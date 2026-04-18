import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Reads + writes the merch-specific notification toggles
/// (push_merch_alerts + email_merch_alerts) via /summaries/preferences.
@immutable
class MerchNotificationPrefs {
  final bool pushEnabled;
  final bool emailEnabled;
  const MerchNotificationPrefs({required this.pushEnabled, required this.emailEnabled});

  /// User-facing single switch: ON if either channel is on.
  bool get anyEnabled => pushEnabled || emailEnabled;
}

class MerchNotificationPrefsNotifier extends StateNotifier<AsyncValue<MerchNotificationPrefs>> {
  final ApiClient _client;
  MerchNotificationPrefsNotifier(this._client) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final userId = await _client.getUserId();
      if (userId == null) {
        throw StateError('No user session');
      }
      final response = await _client.get('/summaries/preferences/$userId');
      final data = response.data as Map<String, dynamic>;
      state = AsyncValue.data(MerchNotificationPrefs(
        pushEnabled: data['push_merch_alerts'] as bool? ?? true,
        emailEnabled: data['email_merch_alerts'] as bool? ?? true,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final userId = await _client.getUserId();
    if (userId == null) return;
    // Optimistic update
    state = AsyncValue.data(MerchNotificationPrefs(pushEnabled: enabled, emailEnabled: enabled));
    try {
      await _client.put(
        '/summaries/preferences/$userId',
        data: {
          'push_merch_alerts': enabled,
          'email_merch_alerts': enabled,
        },
      );
    } catch (e) {
      debugPrint('Failed to update merch notification prefs: $e');
      // Reload to reflect real state
      await load();
      rethrow;
    }
  }
}

final merchNotificationPrefsProvider = StateNotifierProvider<
    MerchNotificationPrefsNotifier, AsyncValue<MerchNotificationPrefs>>((ref) {
  return MerchNotificationPrefsNotifier(ref.watch(apiClientProvider));
});
