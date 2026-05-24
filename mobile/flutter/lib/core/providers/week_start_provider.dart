import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

/// SharedPreferences key for the locally-cached week-start preference.
/// Acts as an offline cache + first-paint value before the backend round-trip
/// resolves. Backend value (when present) wins on the first authenticated
/// fetch — see [WeekStartNotifier._init].
const String _weekStartsSundayKey = 'week_starts_sunday';

/// Provider for the week-start preference (true = Sunday, false = Monday).
final weekStartsSundayProvider =
    StateNotifierProvider<WeekStartNotifier, bool>((ref) {
  return WeekStartNotifier(ref);
});

class WeekStartNotifier extends StateNotifier<bool> {
  final Ref _ref;

  /// True once a backend fetch (or a definitive "no backend value" answer
  /// for an anonymous user) has resolved. Used to gate fire-and-forget
  /// backend writes from [setStartsSunday]: while still loading we still
  /// write to the backend if the user IS authenticated, because the local
  /// state has already been resolved from SharedPreferences.
  bool _backendResolved = false;

  /// Set true when a [setStartsSunday] call failed to PATCH the backend.
  /// On the next [refreshFromBackend] (or app-foreground) we replay the
  /// most-recent local value to the server.
  bool _pendingBackendRetry = false;

  WeekStartNotifier(this._ref) : super(false) {
    _init();
  }

  /// Init order:
  ///   1. SharedPreferences (instant — used for first paint).
  ///   2. If authenticated → GET /users/me/preferences. Backend non-null
  ///      wins (multi-device sync); backend null + local set → one-time
  ///      PATCH up (migrate existing local-only users).
  ///   3. Anonymous → SharedPreferences only.
  Future<void> _init() async {
    // Step 1 — load the local cache for instant first paint.
    bool? localValue;
    try {
      final prefs = await SharedPreferences.getInstance();
      localValue = prefs.getBool(_weekStartsSundayKey);
      if (localValue != null && mounted) {
        state = localValue;
        debugPrint(
          '🕐 [WeekStart] Loaded from SharedPreferences cache: $localValue',
        );
      }
    } catch (e) {
      debugPrint('❌ [WeekStart] Failed to read SharedPreferences: $e');
    }

    // Step 2/3 — try the backend if we look authenticated.
    final authState = _ref.read(authStateProvider);
    if (authState.user == null) {
      _backendResolved = true;
      debugPrint('🕐 [WeekStart] Anonymous — staying on local-only mode');
      return;
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      final res = await apiClient.get<Map<String, dynamic>>(
        '/users/me/preferences',
      );
      final data = res.data;
      final backendValue = data == null ? null : data['week_starts_sunday'];

      if (backendValue is bool) {
        // Backend wins. Mirror into local cache.
        if (mounted && backendValue != state) {
          state = backendValue;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_weekStartsSundayKey, backendValue);
        } catch (e) {
          debugPrint('⚠️ [WeekStart] Failed to update local cache: $e');
        }
        debugPrint(
          '🕐 [WeekStart] Loaded from backend (backend-wins): $backendValue',
        );
      } else if (localValue != null) {
        // Backend has no value yet but we have a local one — migrate it up
        // so the next device sees it.
        debugPrint(
          '🕐 [WeekStart] Backend null + local=$localValue → one-time migrate up',
        );
        await _patchBackend(localValue);
      } else {
        debugPrint('🕐 [WeekStart] No backend value, no local value — default');
      }
    } catch (e) {
      debugPrint('⚠️ [WeekStart] Backend init fetch failed (non-fatal): $e');
    } finally {
      _backendResolved = true;
    }
  }

  /// User-initiated toggle. Local state updates instantly; SharedPreferences
  /// + backend PATCH happen in parallel afterwards.
  Future<void> setStartsSunday(bool value) async {
    if (state != value && mounted) {
      state = value;
    }

    // Always persist to SharedPreferences (local cache + anonymous mode).
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_weekStartsSundayKey, value);
    } catch (e) {
      debugPrint('❌ [WeekStart] Failed to save to SharedPreferences: $e');
    }

    // Fire-and-forget backend sync when authenticated.
    final authState = _ref.read(authStateProvider);
    if (authState.user != null) {
      await _patchBackend(value);
    }
  }

  Future<void> toggle() async {
    await setStartsSunday(!state);
  }

  /// PATCH the backend; remember failure so [refreshFromBackend] can replay.
  Future<void> _patchBackend(bool value) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.patch<Map<String, dynamic>>(
        '/users/me/preferences',
        data: {'week_starts_sunday': value},
      );
      _pendingBackendRetry = false;
      debugPrint('🕐 [WeekStart] Synced to backend: $value');
    } catch (e) {
      _pendingBackendRetry = true;
      debugPrint('⚠️ [WeekStart] Backend PATCH failed, will retry: $e');
    }
  }

  /// Re-pull from backend (call on app foreground / settings open).
  /// Backend value wins. If a previous write failed, replay it first.
  Future<void> refreshFromBackend() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user == null) return;

    // Replay a previously-failed write before re-reading, so our local edit
    // doesn't get clobbered by stale server state.
    if (_pendingBackendRetry) {
      await _patchBackend(state);
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      final res = await apiClient.get<Map<String, dynamic>>(
        '/users/me/preferences',
      );
      final data = res.data;
      final backendValue = data == null ? null : data['week_starts_sunday'];
      if (backendValue is bool && backendValue != state) {
        if (mounted) {
          state = backendValue;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_weekStartsSundayKey, backendValue);
        } catch (_) {}
        debugPrint(
          '🕐 [WeekStart] Conflict resolved (backend-wins): $backendValue',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [WeekStart] refreshFromBackend failed: $e');
    }
  }

  /// Test-only hook — true once init() has resolved.
  @visibleForTesting
  bool get backendResolved => _backendResolved;
}

/// Helper that returns display-order constants based on the preference.
///
/// When Sunday-first: display order [6,0,1,2,3,4,5], labels S M T W T F S
/// When Monday-first: display order [0,1,2,3,4,5,6], labels M T W T F S S
class WeekDisplayConfig {
  final List<int> displayOrder;
  final List<String> dayLabels;
  final bool startsSunday;

  const WeekDisplayConfig._({
    required this.displayOrder,
    required this.dayLabels,
    required this.startsSunday,
  });

  factory WeekDisplayConfig.from(bool startsSunday) {
    if (startsSunday) {
      return const WeekDisplayConfig._(
        displayOrder: [6, 0, 1, 2, 3, 4, 5],
        dayLabels: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
        startsSunday: true,
      );
    }
    return const WeekDisplayConfig._(
      displayOrder: [0, 1, 2, 3, 4, 5, 6],
      dayLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      startsSunday: false,
    );
  }

  /// The first day of the current week as a DateTime.
  DateTime weekStart(DateTime today) {
    if (startsSunday) {
      return today.subtract(Duration(days: today.weekday % 7));
    }
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Convert a data index (0=Mon..6=Sun) to a date within the current
  /// display-week anchored at [weekStartDate].
  DateTime dateForDataIndex(DateTime weekStartDate, int dataIndex) {
    if (startsSunday) {
      // Sunday is offset 0, Monday is offset 1, … Saturday is offset 6
      return weekStartDate.add(Duration(days: (dataIndex + 1) % 7));
    }
    // Monday-first: Monday is offset 0, … Sunday is offset 6
    return weekStartDate.add(Duration(days: dataIndex));
  }
}

/// Derived provider for the display config.
final weekDisplayConfigProvider = Provider<WeekDisplayConfig>((ref) {
  final startsSunday = ref.watch(weekStartsSundayProvider);
  return WeekDisplayConfig.from(startsSunday);
});
