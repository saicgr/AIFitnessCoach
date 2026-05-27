import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fasting.dart';
import '../repositories/fasting_repository.dart';
import '../repositories/auth_repository.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
FastingState? _fastingInMemoryCache;

/// Tracks the user_id this static cache belongs to, so we can flush it on a
/// real account switch and avoid the new user inheriting the prior user's
/// fasting state.
String? _fastingCacheOwnerUserId;

// ===========================================================================
// _ActiveFastDiskCache — stale-while-revalidate disk cache (A2)
// ===========================================================================

/// Persistent (cross-launch) cache for the user's CURRENT active fast.
///
/// An in-progress fast is the one piece of fasting state that must show
/// instantly on a cold start — otherwise the timer appears to reset. Mirrors
/// `_NutritionDiskCache`: a JSON-encoded `FastingRecord` in a versioned,
/// user-scoped envelope.
///
/// NOT date-scoped: a fast legitimately spans midnight (e.g. an 18h fast
/// started at 8 PM), so the only validity gate is the schema version and the
/// user_id. The server reconciliation in `initialize` corrects a fast that
/// was ended on another device.
class _ActiveFastDiskCache {
  static const _prefix = 'active_fast_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  /// Read the persisted active fast, or null when none / schema mismatch /
  /// malformed. Never throws.
  static Future<FastingRecord?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      if (envelope['v'] != _schemaVersion) return null; // drop on schema bump
      final body = envelope['fast'];
      if (body is! Map<String, dynamic>) return null;
      return FastingRecord.fromJson(body);
    } catch (e) {
      debugPrint('🕐 [ActiveFastDiskCache] read failed: $e');
      return null;
    }
  }

  /// Write-through the active fast. Best-effort.
  static Future<void> write(String userId, FastingRecord fast) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'v': _schemaVersion,
          'cached_at': DateTime.now().toIso8601String(),
          'fast': fast.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('🕐 [ActiveFastDiskCache] write failed: $e');
    }
  }

  /// Drop the persisted fast — called when a fast ends/cancels so a stale
  /// timer doesn't resurrect on the next cold start.
  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {/* best-effort */}
  }
}

// ============================================
// Fasting State
// ============================================

/// Complete fasting state including active fast, preferences, streak, and stats
class FastingState {
  final FastingRecord? activeFast;
  final FastingPreferences? preferences;
  final FastingStreak? streak;
  final FastingStats? stats;
  final FastingScore? score;
  final FastingScoreTrend? scoreTrend;
  final WeightCorrelationSummary? weightCorrelation;
  final List<FastingRecord> history;
  final bool isLoading;
  final String? error;
  final bool onboardingCompleted;

  const FastingState({
    this.activeFast,
    this.preferences,
    this.streak,
    this.stats,
    this.score,
    this.scoreTrend,
    this.weightCorrelation,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
  });

  FastingState copyWith({
    FastingRecord? activeFast,
    FastingPreferences? preferences,
    FastingStreak? streak,
    FastingStats? stats,
    FastingScore? score,
    FastingScoreTrend? scoreTrend,
    WeightCorrelationSummary? weightCorrelation,
    List<FastingRecord>? history,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
    bool clearActiveFast = false,
    bool clearError = false,
  }) {
    return FastingState(
      activeFast: clearActiveFast ? null : (activeFast ?? this.activeFast),
      preferences: preferences ?? this.preferences,
      streak: streak ?? this.streak,
      stats: stats ?? this.stats,
      score: score ?? this.score,
      scoreTrend: scoreTrend ?? this.scoreTrend,
      weightCorrelation: weightCorrelation ?? this.weightCorrelation,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Check if user has an active fast
  bool get hasFast => activeFast != null;

  /// Check if fasting feature is enabled for user
  bool get isEnabled => onboardingCompleted && preferences != null;

  /// Get current fasting zone (if fasting)
  FastingZone? get currentZone => activeFast?.currentZone;

  /// Get elapsed time formatted (if fasting)
  String get elapsedTimeFormatted {
    if (activeFast == null) return '--:--';
    final hours = activeFast!.elapsedMinutes ~/ 60;
    final mins = activeFast!.elapsedMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Get remaining time formatted (if fasting)
  String get remainingTimeFormatted {
    if (activeFast == null) return '--:--';
    final remaining = activeFast!.goalDurationMinutes - activeFast!.elapsedMinutes;
    if (remaining <= 0) return 'Goal reached!';
    final hours = remaining ~/ 60;
    final mins = remaining % 60;
    return '${hours}h ${mins}m';
  }
}

// ============================================
// Fasting Notifier
// ============================================

/// Fasting state notifier for managing all fasting state
class FastingNotifier extends StateNotifier<FastingState> {
  final FastingRepository _repository;
  Timer? _refreshTimer;
  String? _initializedUserId;  // Track which user is already initialized

  FastingNotifier(this._repository)
      : super(_fastingInMemoryCache ?? const FastingState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _fastingInMemoryCache = null;
    debugPrint('🧹 [FastingProvider] In-memory cache cleared');
  }

  /// Initialize fasting state for a user
  /// Skips API calls if data is already loaded for this user (prevents redundant calls on tab switch)
  ///
  /// Stale-while-revalidate (A2): before the network round-trip we seed
  /// `activeFast` from the disk cache so an in-progress fast (and its timer)
  /// shows INSTANTLY on a cold restart. The server response below then
  /// reconciles — including correcting a fast that was ended elsewhere.
  Future<void> initialize(String userId, {bool forceRefresh = false}) async {
    // Skip if already initialized for this user (unless force refresh requested)
    if (!forceRefresh && _initializedUserId == userId && !state.isLoading && state.preferences != null) {
      debugPrint('🕐 [FastingProvider] Already initialized for $userId, skipping API calls');
      return;
    }

    // Disk seed — only when in-memory state has no active fast yet (cold
    // start). Renders the running timer immediately while the network call
    // below verifies it.
    if (state.activeFast == null) {
      final cachedFast = await _ActiveFastDiskCache.read(userId);
      if (cachedFast != null && state.activeFast == null) {
        debugPrint('🕐 [FastingProvider] Seeded active fast from disk cache');
        state = state.copyWith(activeFast: cachedFast);
        _startRefreshTimer();
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Initializing for $userId (forceRefresh=$forceRefresh)');

      // Load all data in parallel
      final results = await Future.wait([
        _repository.getActiveFast(userId),
        _repository.getPreferences(userId),
        _repository.getStreak(userId).catchError((_) => const FastingStreak(
              userId: '',
              currentStreak: 0,
              longestStreak: 0,
              totalFastsCompleted: 0,
              totalFastingMinutes: 0,
            )),
        _repository.getStats(userId: userId).catchError((_) => const FastingStats(
              userId: '',
              totalFasts: 0,
              completedFasts: 0,
              avgDurationMinutes: 0,
              longestFastMinutes: 0,
              totalFastingMinutes: 0,
            )),
        _repository.getFastingHistory(userId: userId, limit: 10).catchError((_) => <FastingRecord>[]),
      ]);

      final activeFast = results[0] as FastingRecord?;
      final preferences = results[1] as FastingPreferences?;
      final streak = results[2] as FastingStreak;
      final stats = results[3] as FastingStats;
      final history = results[4] as List<FastingRecord>;

      // Load weight correlation separately (optional data)
      WeightCorrelationSummary? weightCorrelation;
      try {
        final weightResponse = await _repository.getWeightCorrelation(userId: userId);
        weightCorrelation = weightResponse.summary;
      } catch (e) {
        debugPrint('⚠️ [FastingProvider] Weight correlation load error (non-fatal): $e');
      }

      // Calculate fasting score (done after we have stats and streak)
      FastingScore? score;
      FastingScoreTrend? scoreTrend;
      try {
        score = await _repository.calculateFastingScore(userId);
        scoreTrend = await _repository.getScoreTrend(userId);
      } catch (e) {
        debugPrint('⚠️ [FastingProvider] Score calculation error (non-fatal): $e');
      }

      // (A12c) Reconcile the disk-seeded fast with the server's truth in
      // place. `copyWith(activeFast:)` null-coalesces, so a server "no active
      // fast" would NOT clear a disk-seeded one — use `clearActiveFast` when
      // the server says there is none.
      state = state.copyWith(
        activeFast: activeFast,
        clearActiveFast: activeFast == null,
        preferences: preferences,
        streak: streak,
        stats: stats,
        score: score,
        scoreTrend: scoreTrend,
        weightCorrelation: weightCorrelation,
        history: history,
        isLoading: false,
        onboardingCompleted: preferences?.fastingOnboardingCompleted ?? false,
      );
      // Update in-memory cache for instant access on provider recreation
      _fastingInMemoryCache = state;

      // Reconcile the disk cache with the server truth.
      if (activeFast != null) {
        _startRefreshTimer();
        unawaited(_ActiveFastDiskCache.write(userId, activeFast));
      } else {
        _stopRefreshTimer();
        unawaited(_ActiveFastDiskCache.clear(userId));
      }

      // Mark as initialized for this user
      _initializedUserId = userId;

      debugPrint('✅ [FastingProvider] Initialized: hasFast=${activeFast != null}, onboarded=${preferences?.fastingOnboardingCompleted}, score=${score?.score}');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start a new fast
  Future<void> startFast({
    required String userId,
    required FastingProtocol protocol,
    int? customDurationMinutes,
    DateTime? startTime,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Starting fast: ${protocol.displayName}${startTime != null ? ' at $startTime' : ''}');
      final fast = await _repository.startFast(
        userId: userId,
        protocol: protocol,
        customDurationMinutes: customDurationMinutes,
        startTime: startTime,
      );
      state = state.copyWith(activeFast: fast, isLoading: false);
      _startRefreshTimer();
      // Persist so a cold restart shows the running timer instantly (A2).
      unawaited(_ActiveFastDiskCache.write(userId, fast));
      debugPrint('✅ [FastingProvider] Fast started');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Start fast error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// End the current fast
  Future<FastEndResult?> endFast({
    required String userId,
    String? notes,
    String? moodAfter,
    int? energyLevel,
  }) async {
    if (state.activeFast == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Ending fast');
      final result = await _repository.endFast(
        fastId: state.activeFast!.id,
        userId: userId,
        notes: notes,
        moodAfter: moodAfter,
        energyLevel: energyLevel,
      );

      // Stop refresh timer
      _stopRefreshTimer();
      // Drop the disk cache so a stale timer can't resurrect on cold start.
      unawaited(_ActiveFastDiskCache.clear(userId));

      // Refresh streak, stats, and recalculate score
      final streak = await _repository.getStreak(userId);
      final stats = await _repository.getStats(userId: userId);
      final history = await _repository.getFastingHistory(userId: userId, limit: 10);

      // Recalculate and sync fasting score after fast completion
      FastingScore? score;
      FastingScoreTrend? scoreTrend;
      try {
        score = await _repository.calculateFastingScore(userId);
        // Sync to database for historical tracking
        await _repository.syncFastingScore(userId: userId, score: score);
        scoreTrend = await _repository.getScoreTrend(userId);
        debugPrint('📊 [FastingProvider] Score updated: ${score.score}');
      } catch (e) {
        debugPrint('⚠️ [FastingProvider] Score sync error (non-fatal): $e');
      }

      state = state.copyWith(
        clearActiveFast: true,
        streak: streak,
        stats: stats,
        score: score,
        scoreTrend: scoreTrend,
        history: history,
        isLoading: false,
      );

      debugPrint('✅ [FastingProvider] Fast ended: ${result.record.completionPercentage?.toStringAsFixed(0) ?? 'N/A'}% complete');
      return result;
    } catch (e) {
      debugPrint('❌ [FastingProvider] End fast error: $e');

      // If fast not found (404), it was already ended/cancelled - clear local state
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        debugPrint('⚠️ [FastingProvider] Fast already ended on server, clearing local state');
        _stopRefreshTimer();
        unawaited(_ActiveFastDiskCache.clear(userId));

        // Refresh data from server to sync state
        try {
          final streak = await _repository.getStreak(userId);
          final stats = await _repository.getStats(userId: userId);
          final history = await _repository.getFastingHistory(userId: userId, limit: 10);
          state = state.copyWith(
            clearActiveFast: true,
            streak: streak,
            stats: stats,
            history: history,
            isLoading: false,
            clearError: true,
          );
        } catch (_) {
          state = state.copyWith(clearActiveFast: true, isLoading: false, clearError: true);
        }
        return null;
      }

      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Cancel the current fast (no credit)
  Future<void> cancelFast(String userId) async {
    if (state.activeFast == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🚫 [FastingProvider] Cancelling fast');
      await _repository.cancelFast(
        fastId: state.activeFast!.id,
        userId: userId,
      );
      _stopRefreshTimer();
      unawaited(_ActiveFastDiskCache.clear(userId));
      state = state.copyWith(clearActiveFast: true, isLoading: false);
      debugPrint('✅ [FastingProvider] Fast cancelled');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Cancel fast error: $e');

      // If fast not found (404), it was already ended/cancelled - clear local state
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        debugPrint('⚠️ [FastingProvider] Fast already gone on server, clearing local state');
        _stopRefreshTimer();
        unawaited(_ActiveFastDiskCache.clear(userId));
        state = state.copyWith(clearActiveFast: true, isLoading: false, clearError: true);
        return;
      }

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Pause the current active fast (suspends elapsed-time accrual). (Task I)
  Future<void> pauseFast(String userId) async {
    if (state.activeFast == null) return;
    try {
      debugPrint('⏸️ [FastingProvider] Pausing fast');
      final updated = await _repository.pauseFast(
        fastId: state.activeFast!.id,
        userId: userId,
      );
      state = state.copyWith(activeFast: updated);
      unawaited(_ActiveFastDiskCache.write(userId, updated));
      debugPrint('✅ [FastingProvider] Fast paused');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Pause fast error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Resume the current paused fast. (Task I)
  Future<void> resumeFast(String userId) async {
    if (state.activeFast == null) return;
    try {
      debugPrint('▶️ [FastingProvider] Resuming fast');
      final updated = await _repository.resumeFast(
        fastId: state.activeFast!.id,
        userId: userId,
      );
      state = state.copyWith(activeFast: updated);
      unawaited(_ActiveFastDiskCache.write(userId, updated));
      debugPrint('✅ [FastingProvider] Fast resumed');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Resume fast error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Undo a just-ended fast — re-opens it back to active within the backend's
  /// short undo window. [fastId] is the id of the fast that was ended. (Task I)
  Future<bool> undoEndFast({
    required String userId,
    required String fastId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('↩️ [FastingProvider] Undoing end of fast $fastId');
      final reopened = await _repository.undoEndFast(
        fastId: fastId,
        userId: userId,
      );

      // Refresh streak/stats/history so the undone fast leaves history.
      final streak = await _repository.getStreak(userId);
      final stats = await _repository.getStats(userId: userId);
      final history = await _repository.getFastingHistory(
        userId: userId,
        limit: 10,
      );

      state = state.copyWith(
        activeFast: reopened,
        streak: streak,
        stats: stats,
        history: history,
        isLoading: false,
      );
      _startRefreshTimer();
      // Re-persist the reopened fast so a cold restart shows the timer again.
      unawaited(_ActiveFastDiskCache.write(userId, reopened));
      debugPrint('✅ [FastingProvider] Fast end undone');
      return true;
    } catch (e) {
      debugPrint('❌ [FastingProvider] Undo end fast error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Edit a past (completed) fast's start/end times. Recomputes duration and
  /// completion on the backend and refreshes history + stats. (Task I)
  Future<bool> editFast({
    required String userId,
    required String fastId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      debugPrint('✏️ [FastingProvider] Editing fast $fastId');
      final edited = await _repository.editFast(
        fastId: fastId,
        userId: userId,
        startTime: startTime,
        endTime: endTime,
      );

      // Refresh dependent aggregates so edits propagate everywhere.
      final streak = await _repository.getStreak(userId);
      final stats = await _repository.getStats(userId: userId);
      final history = await _repository.getFastingHistory(
        userId: userId,
        limit: 50,
      );

      // Splice the edited record into the in-memory history list too.
      final patched = [
        for (final r in history) r.id == edited.id ? edited : r,
      ];

      state = state.copyWith(
        streak: streak,
        stats: stats,
        history: patched,
      );
      debugPrint('✅ [FastingProvider] Fast edited');
      return true;
    } catch (e) {
      debugPrint('❌ [FastingProvider] Edit fast error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Save fasting preferences with optimistic UI. State updates synchronously
  /// so any sheet bound to it can pop in the same frame; persistence runs in
  /// the background and rolls back on failure.
  Future<void> savePreferences({
    required String userId,
    required FastingPreferences preferences,
  }) async {
    final previous = state.preferences;
    state = state.copyWith(preferences: preferences, clearError: true);
    debugPrint('💾 [FastingProvider] Optimistic preferences update applied');

    unawaited(() async {
      try {
        final saved = await _repository.savePreferences(
          userId: userId,
          preferences: preferences,
        );
        state = state.copyWith(preferences: saved);
        debugPrint('✅ [FastingProvider] Preferences persisted to backend');
      } catch (e) {
        debugPrint('❌ [FastingProvider] Save failed, rolling back: $e');
        state = state.copyWith(
          preferences: previous,
          error: e.toString(),
        );
      }
    }());
  }

  /// Complete fasting onboarding
  Future<void> completeOnboarding({
    required String userId,
    required FastingPreferences preferences,
    required List<String> safetyAcknowledgments,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🎓 [FastingProvider] Completing onboarding');
      await _repository.completeOnboarding(
        userId: userId,
        preferences: preferences,
        safetyAcknowledgments: safetyAcknowledgments,
      );
      state = state.copyWith(
        preferences: preferences.copyWith(fastingOnboardingCompleted: true),
        onboardingCompleted: true,
        isLoading: false,
      );
      debugPrint('✅ [FastingProvider] Onboarding completed');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Onboarding error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh fasting history
  Future<void> refreshHistory(String userId) async {
    try {
      final history = await _repository.getFastingHistory(userId: userId, limit: 50);
      state = state.copyWith(history: history);
    } catch (e) {
      debugPrint('❌ [FastingProvider] Refresh history error: $e');
    }
  }

  /// Force refresh the active fast state (useful for timer updates)
  void refreshActiveFast() {
    if (state.activeFast == null) return;

    // Just trigger a state update to recalculate computed properties
    state = state.copyWith(
      activeFast: state.activeFast!.copyWith(
        // No actual changes, just triggers rebuild
      ),
    );
  }

  /// Start periodic refresh timer for active fast
  void _startRefreshTimer() {
    _stopRefreshTimer();
    // Refresh every minute to update elapsed time
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshActiveFast();
    });
  }

  /// Stop refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Sync fasting state from watch event data.
  /// Called when fasting is started/ended on the watch.
  void syncFromWatch(Map<String, dynamic> data) {
    final eventType = data['eventType'] as String? ?? '';
    final protocol = data['protocol'] as String? ?? '16:8';
    final elapsedMinutes = data['elapsedMinutes'] as int? ?? 0;
    final sessionId = data['sessionId'] as String?;

    debugPrint('🔄 [FastingProvider] Syncing from watch: $eventType');

    if (eventType == 'started') {
      // Watch started a fast - create a local representation
      // Note: The actual fast should have been created on the backend by the watch
      // This just ensures local state is in sync
      final startTime = DateTime.now().subtract(Duration(minutes: elapsedMinutes));

      // We don't have all the data needed to create a full FastingRecord here,
      // so just refresh from the server to get the actual data
      if (_initializedUserId != null) {
        initialize(_initializedUserId!, forceRefresh: true);
      }
    } else if (eventType == 'ended' || eventType == 'completed') {
      // Watch ended the fast - refresh to get updated state
      _stopRefreshTimer();
      if (_initializedUserId != null) {
        initialize(_initializedUserId!, forceRefresh: true);
      }
    }
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}

// ============================================
// Providers
// ============================================

/// Fasting state provider
final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  // Watch user_id only — full AuthState churns on token refresh. Flush the
  // static in-memory cache on a real account switch.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _fastingCacheOwnerUserId) {
    _fastingCacheOwnerUserId = userId;
    _fastingInMemoryCache = null;
  }
  return FastingNotifier(
    ref.watch(fastingRepositoryProvider),
  );
});

/// Active fast provider (convenience)
final activeFastProvider = Provider<FastingRecord?>((ref) {
  return ref.watch(fastingProvider).activeFast;
});

/// Is fasting provider (convenience)
final isFastingProvider = Provider<bool>((ref) {
  return ref.watch(fastingProvider).hasFast;
});

/// Current fasting zone provider (convenience)
final currentFastingZoneProvider = Provider<FastingZone?>((ref) {
  return ref.watch(fastingProvider).currentZone;
});

/// Fasting streak provider (convenience)
final fastingStreakProvider = Provider<FastingStreak?>((ref) {
  return ref.watch(fastingProvider).streak;
});

/// Fasting onboarding completed provider (convenience)
final fastingOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(fastingProvider).onboardingCompleted;
});

// ============================================
// Timer Provider for UI Updates
// ============================================

/// Provides elapsed seconds for active fast (updates every second)
final fastingTimerProvider = StreamProvider.autoDispose<int>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) {
    return Stream.value(0);
  }

  return Stream.periodic(const Duration(seconds: 1), (count) {
    final elapsed = DateTime.now().difference(activeFast.startTime);
    return elapsed.inSeconds;
  });
});

/// Computed elapsed time in minutes
final fastingElapsedMinutesProvider = Provider<int>((ref) {
  final seconds = ref.watch(fastingTimerProvider).value ?? 0;
  return seconds ~/ 60;
});

/// Computed progress percentage (0.0 - 1.0)
final fastingProgressProvider = Provider<double>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) return 0.0;

  final elapsedMinutes = ref.watch(fastingElapsedMinutesProvider);
  final goalMinutes = activeFast.goalDurationMinutes;
  if (goalMinutes <= 0) return 0.0;

  return (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
});

/// Computed current zone based on elapsed time
final computedFastingZoneProvider = Provider<FastingZone>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) return FastingZone.fed;

  final elapsedMinutes = ref.watch(fastingElapsedMinutesProvider);
  return FastingZone.fromElapsedMinutes(elapsedMinutes);
});

// ============================================
// AI Fasting Insight Provider (Task D)
// ============================================

/// AI-generated plain-English fasting insight for the current user.
///
/// Backed by `POST /insights/{user_id}/fasting-analysis` (Gemini, 6h-cached
/// server-side). Returns an honest empty-state string when there is no
/// fasting history. Auto-disposes so it re-fetches when the fasting screen is
/// reopened; pass the current [FastingState] aggregates via the family arg is
/// avoided — it reads them off [fastingProvider] directly to stay in sync.
final fastingInsightProvider =
    FutureProvider.autoDispose<String>((ref) async {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId == null) {
    throw Exception('Sign in to see AI insights.');
  }
  // ref.read (not watch): this provider is autoDispose, so it still re-fetches
  // once each time the fasting screen is reopened — the intended behaviour.
  // Watching the whole FastingState re-ran this on every 1-minute elapsed-time
  // tick from _startRefreshTimer, POSTing the Gemini-backed fasting-analysis
  // endpoint once per minute (cost + rate-limit pressure + hammered the
  // endpoint during its 404 deploy gap).
  final fasting = ref.read(fastingProvider);
  final streak = fasting.streak;
  final stats = fasting.stats;
  if (streak == null || stats == null) {
    throw Exception('Fasting data not loaded yet.');
  }
  final repository = ref.watch(fastingRepositoryProvider);
  return repository.getFastingInsight(
    userId: userId,
    streak: streak,
    stats: stats,
    activeFast: fasting.activeFast,
  );
});

// ============================================
// Safety Check Provider
// ============================================

/// Provider to check if user can use fasting features
final fastingSafetyCheckProvider = FutureProvider.autoDispose.family<SafetyScreeningResult, String>((ref, userId) async {
  final repository = ref.watch(fastingRepositoryProvider);
  return repository.checkSafetyEligibility(userId);
});
