import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_celebration.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// Holds the queue of trophies the user hasn't seen a celebration for yet.
/// Populated by `refresh()` (called on login + app resume + manual pull).
///
/// Consumers (app lifecycle listener in main_shell) read `.pending`, render
/// the ceremony, then call `ack()` once the stack is dismissed so the
/// server cursor advances and the same trophies never replay.
class PendingCelebrationsState {
  final List<PendingCelebration> pending;
  final bool isLoading;
  final bool isFetchInFlight;

  const PendingCelebrationsState({
    required this.pending,
    this.isLoading = false,
    this.isFetchInFlight = false,
  });

  static const empty = PendingCelebrationsState(pending: []);

  PendingCelebrationsState copyWith({
    List<PendingCelebration>? pending,
    bool? isLoading,
    bool? isFetchInFlight,
  }) {
    return PendingCelebrationsState(
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      isFetchInFlight: isFetchInFlight ?? this.isFetchInFlight,
    );
  }
}


class PendingCelebrationsNotifier
    extends StateNotifier<PendingCelebrationsState> {
  final ApiClient _api;
  final Ref _ref;

  PendingCelebrationsNotifier(this._api, this._ref)
      : super(PendingCelebrationsState.empty);

  Future<void> refresh() async {
    if (state.isFetchInFlight) return; // Debounce parallel calls
    state = state.copyWith(isFetchInFlight: true);
    try {
      final userId = _ref.read(authStateProvider).user?.id;
      if (userId == null) {
        state = state.copyWith(isFetchInFlight: false, isLoading: false);
        return;
      }

      final resp = await _api
          .get('/progress/trophies/$userId/pending-celebrations');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = (resp.data as Map).cast<String, dynamic>();
        final rawList = (data['pending'] as List?) ?? const [];
        final pending = rawList
            .whereType<Map>()
            .map((m) => PendingCelebration.fromJson(
                  m.cast<String, dynamic>(),
                ))
            .toList();
        state = state.copyWith(
          pending: pending,
          isLoading: false,
          isFetchInFlight: false,
        );
        return;
      }
    } catch (e) {
      debugPrint('PendingCelebrationsNotifier.refresh error: $e');
    }
    state = state.copyWith(isFetchInFlight: false, isLoading: false);
  }

  /// Clear local queue and tell the server to bump its cursor. Safe to
  /// call even if the queue is empty (no-op).
  Future<void> ack() async {
    if (state.pending.isEmpty) return;
    final userId = _ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    // Optimistically clear — if the POST fails the worst case is the
    // stack replays once on next app open, which is acceptable.
    state = state.copyWith(pending: const []);
    try {
      await _api.post(
        '/progress/trophies/$userId/ack-celebration',
        data: {
          'ack_timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('PendingCelebrationsNotifier.ack error: $e');
    }
  }
}


final pendingCelebrationsProvider = StateNotifierProvider<
    PendingCelebrationsNotifier, PendingCelebrationsState>((ref) {
  final api = ref.watch(apiClientProvider);
  return PendingCelebrationsNotifier(api, ref);
});
