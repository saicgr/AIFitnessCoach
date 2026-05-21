/// Deload-status provider — backs the home-screen deload recommendation card.
///
/// Calls the existing (previously dead-code) `BodyAnalyzerRepository
/// .triggerDeloadCheck()` endpoint, layered with:
///   • a 12h SharedPreferences cache so the home screen renders instantly and
///     we don't re-hit the endpoint on every home rebuild;
///   • a 7-day user-dismiss suppression (`deloadDismissedAt`);
///   • an "already in a deload mesocycle" guard via [MesocyclePlanner].
///
/// Per `feedback_no_silent_fallbacks.md` the network error is NOT swallowed
/// into a fake "no deload" — it is logged and surfaced as an AsyncError so
/// the card can choose to hide (UX choice) while the bug is still visible in
/// logs. The card treats both error and `needsDeload == false` as "hide".
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_analyzer.dart';
import '../repositories/body_analyzer_repository.dart';
import '../../services/mesocycle_planner.dart';

/// SharedPreferences keys owned by the deload card.
class DeloadPrefsKeys {
  DeloadPrefsKeys._();

  /// ISO-8601 timestamp of the last successful deload check + its payload.
  static const String cache = 'deload_status_cache_v1';

  /// ISO-8601 timestamp of when the user last dismissed the deload card.
  static const String dismissedAt = 'deloadDismissedAt';
}

/// 12h cache window for the deload check result.
const Duration _deloadCacheTtl = Duration(hours: 12);

/// How long a user dismissal suppresses the card.
const Duration _deloadDismissSuppression = Duration(days: 7);

/// Resolved deload status for the home card.
///
/// [shouldShow] folds in every hide reason (dismissed, already deloading,
/// not needed) so the widget layer stays dumb.
@immutable
class DeloadStatus {
  /// Raw API verdict.
  final bool needsDeload;

  /// API-provided human reason (verbatim into the card body).
  final String reason;

  /// True when the active mesocycle is already a deload week — card hides.
  final bool alreadyDeloading;

  /// True when the user dismissed the card inside the 7-day window.
  final bool dismissedRecently;

  const DeloadStatus({
    required this.needsDeload,
    required this.reason,
    required this.alreadyDeloading,
    required this.dismissedRecently,
  });

  /// Empty / "nothing to show" status.
  static const DeloadStatus none = DeloadStatus(
    needsDeload: false,
    reason: '',
    alreadyDeloading: false,
    dismissedRecently: false,
  );

  /// The card renders only when the API says deload is needed AND we are not
  /// already in a deload block AND the user has not recently dismissed it.
  bool get shouldShow =>
      needsDeload &&
      !alreadyDeloading &&
      !dismissedRecently &&
      reason.trim().isNotEmpty;

  DeloadStatus copyWith({
    bool? needsDeload,
    String? reason,
    bool? alreadyDeloading,
    bool? dismissedRecently,
  }) {
    return DeloadStatus(
      needsDeload: needsDeload ?? this.needsDeload,
      reason: reason ?? this.reason,
      alreadyDeloading: alreadyDeloading ?? this.alreadyDeloading,
      dismissedRecently: dismissedRecently ?? this.dismissedRecently,
    );
  }
}

/// FutureProvider.autoDispose — recomputed when the home screen mounts.
///
/// Resolution order:
///   1. If the user dismissed within 7 days → return a dismissed status
///      without hitting the network at all.
///   2. If the active mesocycle is already a deload → return alreadyDeloading
///      without hitting the network.
///   3. Read the 12h cache; if fresh, use it.
///   4. Otherwise call the API, persist the result, and return it.
final deloadStatusProvider =
    FutureProvider.autoDispose<DeloadStatus>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Dismiss-suppression gate — cheapest check, no I/O beyond prefs.
  if (_isDismissedRecently(prefs)) {
    debugPrint('🛌 [Deload] suppressed — dismissed within 7 days');
    return DeloadStatus.none.copyWith(dismissedRecently: true);
  }

  // 2. Already-in-deload gate. MesocyclePlanner reads local prefs only, so
  //    this is fast and offline-safe.
  bool alreadyDeloading = false;
  try {
    final ctx = await MesocyclePlanner.getCurrentContext();
    alreadyDeloading = ctx?.isDeload ?? false;
  } catch (e) {
    // A planner read failure must not block the card — log and continue as
    // "not in a deload block" so the API verdict still gets a chance.
    debugPrint('⚠️ [Deload] mesocycle context read failed: $e');
  }
  if (alreadyDeloading) {
    debugPrint('🛌 [Deload] suppressed — already in a deload mesocycle');
    return DeloadStatus.none.copyWith(alreadyDeloading: true);
  }

  // 3. 12h cache.
  final cached = _readCache(prefs);
  if (cached != null) {
    debugPrint('🛌 [Deload] cache hit — needsDeload=${cached.needsDeload}');
    return cached.copyWith(alreadyDeloading: false, dismissedRecently: false);
  }

  // 4. Network. Errors bubble — the provider surfaces AsyncError; the card
  //    treats that as "hide" but the failure stays loud in logs.
  final repo = ref.read(bodyAnalyzerRepositoryProvider);
  final DeloadCheckResult result = await repo.triggerDeloadCheck();
  debugPrint(
      '🛌 [Deload] API result — needsDeload=${result.needsDeload} '
      'reason="${result.reason}"');

  final status = DeloadStatus(
    needsDeload: result.needsDeload,
    reason: result.reason,
    alreadyDeloading: false,
    dismissedRecently: false,
  );
  await _writeCache(prefs, status);
  return status;
});

/// Persist a dismissal and invalidate the provider so the card disappears.
///
/// Called from the card's dismiss action. Suppresses the card for 7 days.
Future<void> dismissDeloadCard(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    DeloadPrefsKeys.dismissedAt,
    DateTime.now().toIso8601String(),
  );
  debugPrint('🛌 [Deload] dismissed by user — suppressed for 7 days');
  ref.invalidate(deloadStatusProvider);
}

// ─── Internals ───────────────────────────────────────────────────────────────

bool _isDismissedRecently(SharedPreferences prefs) {
  final raw = prefs.getString(DeloadPrefsKeys.dismissedAt);
  if (raw == null) return false;
  final at = DateTime.tryParse(raw);
  if (at == null) return false;
  return DateTime.now().difference(at) < _deloadDismissSuppression;
}

/// Returns the cached status when it exists and is within the 12h TTL.
DeloadStatus? _readCache(SharedPreferences prefs) {
  final raw = prefs.getString(DeloadPrefsKeys.cache);
  if (raw == null) return null;
  try {
    final map = json.decode(raw) as Map<String, dynamic>;
    final savedAtIso = map['saved_at'] as String?;
    if (savedAtIso == null) return null;
    final savedAt = DateTime.tryParse(savedAtIso);
    if (savedAt == null) return null;
    if (DateTime.now().difference(savedAt) >= _deloadCacheTtl) return null;
    return DeloadStatus(
      needsDeload: map['needs_deload'] as bool? ?? false,
      reason: map['reason'] as String? ?? '',
      alreadyDeloading: false,
      dismissedRecently: false,
    );
  } catch (e) {
    debugPrint('⚠️ [Deload] cache parse failed, ignoring: $e');
    return null;
  }
}

Future<void> _writeCache(SharedPreferences prefs, DeloadStatus status) async {
  final payload = json.encode({
    'saved_at': DateTime.now().toIso8601String(),
    'needs_deload': status.needsDeload,
    'reason': status.reason,
  });
  await prefs.setString(DeloadPrefsKeys.cache, payload);
}
