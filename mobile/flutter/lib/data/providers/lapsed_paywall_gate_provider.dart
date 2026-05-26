import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the most recent moment we routed a lapsed unsubscribed user to the
/// paywall. Prevents the post-auth router from looping them back every time
/// the app foregrounds.
///
/// Pattern mirrors the [last_app_open_ts] key used by [app.dart] —
/// SharedPreferences is the durable store, this provider mirrors the value
/// in memory so the GoRouter `redirect:` callback (which is synchronous) can
/// gate without an async read each tick.
///
/// Wired by [app_router.dart] `_handleAuthRedirect`:
///   1. Read [shouldShowNow] inside the redirect — synchronous.
///   2. If it returns true AND the user is lapsed + unsubscribed, call
///      [markShown] BEFORE returning `/paywall-pricing` so subsequent
///      redirect ticks observe the suppression window.
class LapsedPaywallGateNotifier extends StateNotifier<int?> {
  static const String _kPrefsKey = 'winback_paywall_shown_ts';

  /// Suppression window after a winback route. While inside this window the
  /// gate returns `false` regardless of `days_since_last_workout`. Tuned to
  /// 24h so a user who dismisses the paywall in the morning isn't re-shown
  /// it that evening — but a return next day re-evaluates.
  static const Duration _kSuppressionWindow = Duration(hours: 24);

  LapsedPaywallGateNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kPrefsKey);
      if (ms != null) {
        state = ms;
      }
    } catch (_) {
      // Fail open — better to occasionally show the paywall twice than to
      // hard-block it when SharedPreferences is unavailable.
    }
  }

  /// Returns true if a winback paywall route is allowed right now.
  ///
  /// `false` while we're inside the [_kSuppressionWindow] after a previous
  /// route. The check is synchronous and uses the in-memory mirror, so it
  /// is safe to call from a GoRouter `redirect:` callback.
  bool shouldShowNow() {
    final lastShown = state;
    if (lastShown == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - lastShown;
    return age >= _kSuppressionWindow.inMilliseconds;
  }

  /// Mark the winback paywall as shown right now. Persists to
  /// SharedPreferences AND updates the in-memory state synchronously so the
  /// next redirect tick observes the suppression window.
  ///
  /// Fire-and-forget — the in-memory bump happens immediately; the prefs
  /// write happens in the background. A crash between the two would leave
  /// the user open to a re-route, which is the safe-fail direction.
  void markShown() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    state = nowMs;
    // ignore: discarded_futures
    _persist(nowMs);
  }

  Future<void> _persist(int ms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrefsKey, ms);
    } catch (_) {
      // Safe to swallow — see _load comment.
    }
  }
}

final lapsedPaywallGateProvider =
    StateNotifierProvider<LapsedPaywallGateNotifier, int?>((ref) {
  return LapsedPaywallGateNotifier();
});
