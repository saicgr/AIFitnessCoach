import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/privacy_settings.dart';
import '../services/api_client.dart';
import 'discover_provider.dart';

/// StateNotifier for the three leaderboard privacy toggles.
///
/// Writes are optimistic: the UI updates immediately; if the PUT fails the
/// previous state is restored. Reads go through `/users/me/privacy`.
class PrivacySettingsNotifier extends StateNotifier<AsyncValue<PrivacySettings>> {
  final Ref _ref;

  PrivacySettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  ApiClient get _client => _ref.read(apiClientProvider);

  Future<void> load() async {
    try {
      final res = await _client.get('/users/me/privacy');
      state = AsyncValue.data(
        PrivacySettings.fromJson(res.data as Map<String, dynamic>),
      );
    } catch (e, st) {
      debugPrint('privacy load failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setShowOnLeaderboard(bool value) =>
      _update((s) => s.copyWith(showOnLeaderboard: value));

  Future<void> setAnonymous(bool value) =>
      _update((s) => s.copyWith(leaderboardAnonymous: value));

  Future<void> setStatsVisible(bool value) =>
      _update((s) => s.copyWith(profileStatsVisible: value));

  /// Optimistic update with server rollback on error.
  ///
  /// After a successful PUT we also invalidate discoverSnapshotProvider so
  /// the Discover tab reflects the new privacy state immediately. Without
  /// this, the snapshot provider holds the stale avatar/name tuple and the
  /// user sees themselves un-anonymized until they pull-to-refresh — making
  /// the toggle feel broken.
  Future<void> _update(PrivacySettings Function(PrivacySettings) mut) async {
    final prev = state.valueOrNull;
    if (prev == null) return;
    final next = mut(prev);
    state = AsyncValue.data(next);
    try {
      await _client.put('/users/me/privacy', data: next.toJson());
      _ref.invalidate(discoverSnapshotProvider);
    } catch (e) {
      debugPrint('privacy write failed, rolling back: $e');
      state = AsyncValue.data(prev);
      rethrow;
    }
  }
}

final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, AsyncValue<PrivacySettings>>(
  (ref) => PrivacySettingsNotifier(ref),
);
