import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_celebration.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// SharedPreferences key holding the set of trophy IDs the user has already
/// dismissed in a ceremony on THIS device. Used as a client-side safety net
/// so a trophy never re-plays even if the backend cursor fails to advance
/// (e.g. transient ack POST failure, server-side cursor write silently
/// no-ops, clock skew between client + server). Idempotent: write is
/// additive, never cleared except on logout.
const _kAckedTrophyIdsKey = 'acked_trophy_ids_v1';

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

        // Filter out trophies the user has already dismissed on this
        // device. Defends against backend cursor failures that would
        // otherwise replay the same trophy on every app open.
        final ackedIds = await _loadAckedTrophyIds();
        final filtered = pending
            .where((t) => !ackedIds.contains(t.trophyId))
            .toList();

        state = state.copyWith(
          pending: filtered,
          isLoading: false,
          isFetchInFlight: false,
        );

        // If the server returned trophies we'd already locally acked, fire
        // an ack POST so the backend cursor catches up too. Best-effort —
        // local filter is the source of truth for "shown".
        if (filtered.length < pending.length) {
          unawaited(_postAck(userId, pending));
        }
        return;
      }
    } catch (e) {
      debugPrint('PendingCelebrationsNotifier.refresh error: $e');
    }
    state = state.copyWith(isFetchInFlight: false, isLoading: false);
  }

  /// Clear local queue, persist trophy IDs locally so they never replay,
  /// and tell the server to bump its cursor. Safe to call even if the
  /// queue is empty (no-op).
  Future<void> ack() async {
    if (state.pending.isEmpty) return;
    final userId = _ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final justShown = state.pending;

    // Persist the dismissed trophy IDs LOCALLY before anything else.
    // This is the source of truth — even if the network ack POST fails,
    // these trophies will be filtered out of every future refresh.
    await _persistAckedTrophyIds(justShown.map((t) => t.trophyId));

    // Optimistically clear in-memory state.
    state = state.copyWith(pending: const []);

    // Best-effort sync the cursor with the backend so it stops returning
    // these trophies for OTHER devices the user might have. Use the MAX
    // earned_at from the trophies the user actually saw (not now()) so
    // trophies awarded between the refresh and the ack aren't lost.
    await _postAck(userId, justShown);
  }

  Future<void> _postAck(
    String userId,
    List<PendingCelebration> shown,
  ) async {
    if (shown.isEmpty) return;
    try {
      // Advance cursor to the latest trophy the user actually acked
      // (server uses strict `>` so this excludes everything in `shown`).
      // Falling back to now() if for some reason earnedAt is missing.
      final latest = shown
          .map((t) => t.earnedAt)
          .fold<DateTime>(shown.first.earnedAt,
              (a, b) => b.isAfter(a) ? b : a);
      await _api.post(
        '/progress/trophies/$userId/ack-celebration',
        data: {
          'ack_timestamp': latest.toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('PendingCelebrationsNotifier.ack POST error: $e');
    }
  }

  Future<Set<String>> _loadAckedTrophyIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kAckedTrophyIdsKey) ?? const [];
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _persistAckedTrophyIds(Iterable<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing =
          prefs.getStringList(_kAckedTrophyIdsKey)?.toSet() ?? <String>{};
      existing.addAll(ids.where((id) => id.isNotEmpty));
      await prefs.setStringList(_kAckedTrophyIdsKey, existing.toList());
    } catch (e) {
      debugPrint('PendingCelebrationsNotifier persist error: $e');
    }
  }
}


final pendingCelebrationsProvider = StateNotifierProvider<
    PendingCelebrationsNotifier, PendingCelebrationsState>((ref) {
  final api = ref.watch(apiClientProvider);
  return PendingCelebrationsNotifier(api, ref);
});
