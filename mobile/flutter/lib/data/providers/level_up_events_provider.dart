import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/level_up_event.dart';
import '../services/api_client.dart';

@immutable
class LevelUpEventsState {
  final bool loading;
  final Object? error;
  final List<LevelUpEvent> events;
  const LevelUpEventsState({
    this.loading = false,
    this.error,
    this.events = const [],
  });

  LevelUpEventsState copyWith({
    bool? loading,
    Object? error,
    List<LevelUpEvent>? events,
    bool clearError = false,
  }) =>
      LevelUpEventsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        events: events ?? this.events,
      );
}

class LevelUpEventsNotifier extends StateNotifier<LevelUpEventsState> {
  final ApiClient _client;
  LevelUpEventsNotifier(this._client) : super(const LevelUpEventsState());

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await _client.get('/xp/level-ups/unacknowledged');
      final data = response.data as Map<String, dynamic>;
      final rows = (data['events'] as List? ?? [])
          .map((j) => LevelUpEvent.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(loading: false, events: rows);
    } catch (e) {
      debugPrint('load level-up events failed: $e');
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Mark one or more events as acknowledged. If [eventIds] is null or empty,
  /// acknowledges every outstanding event for the current user.
  Future<void> acknowledge({List<String>? eventIds}) async {
    try {
      await _client.post(
        '/xp/level-ups/acknowledge',
        data: {'event_ids': eventIds},
      );
      // Optimistically clear acknowledged ones from state
      if (eventIds == null || eventIds.isEmpty) {
        state = state.copyWith(events: const []);
      } else {
        final remaining = state.events.where((e) => !eventIds.contains(e.id)).toList();
        state = state.copyWith(events: remaining);
      }
    } catch (e) {
      debugPrint('ack level-ups failed: $e');
    }
  }
}

final levelUpEventsProvider =
    StateNotifierProvider<LevelUpEventsNotifier, LevelUpEventsState>((ref) {
  return LevelUpEventsNotifier(ref.watch(apiClientProvider));
});

final unackedLevelUpCountProvider =
    Provider<int>((ref) => ref.watch(levelUpEventsProvider).events.length);
