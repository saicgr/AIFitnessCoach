import 'dart:async';
import 'dart:math' show min, Random;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../services/connectivity_service.dart';
import '../../data/services/api_client.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// State for the sync engine.
class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int deadLetterCount;
  final bool hasAuthError;
  final DateTime? lastSyncAt;
  final String? lastError;
  final String? lastSyncError;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.deadLetterCount = 0,
    this.hasAuthError = false,
    this.lastSyncAt,
    this.lastError,
    this.lastSyncError,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? deadLetterCount,
    bool? hasAuthError,
    DateTime? lastSyncAt,
    String? lastError,
    String? lastSyncError,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      deadLetterCount: deadLetterCount ?? this.deadLetterCount,
      hasAuthError: hasAuthError ?? this.hasAuthError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }
}

// ---------------------------------------------------------------------------
// Conflict resolution
// ---------------------------------------------------------------------------

/// Strategy for resolving sync conflicts.
enum ConflictStrategy { clientWins, serverWins, lastWriteWins }

/// Determines conflict strategy per entity type.
ConflictStrategy conflictStrategyFor(String entityType) {
  switch (entityType) {
    case 'workout_log':
    case 'readiness':
      return ConflictStrategy.clientWins;
    case 'workout':
      return ConflictStrategy.serverWins;
    case 'user_profile':
      return ConflictStrategy.lastWriteWins;
    default:
      return ConflictStrategy.lastWriteWins;
  }
}

/// Critical entity types that get higher max retries.
const _criticalEntityTypes = {'workout_log', 'workout_completion', 'readiness'};
const _criticalMaxRetries = 50;

// ---------------------------------------------------------------------------
// Sync Engine
// ---------------------------------------------------------------------------

/// Processes the pending sync queue with exponential backoff.
///
/// - Processes items ordered by priority ASC, then createdAt ASC
/// - Exponential backoff: 1s -> 2s -> 4s -> 8s -> 60s max (with 20% jitter)
/// - Items exceeding maxRetries move to dead_letter status
/// - Auto-triggers when connectivity transitions offline -> online
/// - Recovers stuck in_progress items and dead letters before each sync pass
/// - Critical entity types (workout_log, workout_completion, readiness) get 50 retries
class SyncEngineNotifier extends StateNotifier<SyncState> {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final Ref _ref;
  Timer? _retryTimer;
  bool _disposed = false;
  StreamSubscription<int>? _deadLetterSub;

  SyncEngineNotifier(this._db, this._apiClient, this._ref)
      : super(const SyncState()) {
    _watchPendingCount();
    _watchDeadLetterCount();
    _listenForConnectivity();
  }

  /// Watch pending count and keep state updated.
  void _watchPendingCount() {
    _db.syncQueueDao.getPendingCount().listen(
      (count) {
        if (!_disposed) {
          state = state.copyWith(pendingCount: count);
        }
      },
      onError: (e) {
        debugPrint('❌ [SyncEngine] Error watching pending count: $e');
      },
    );
  }

  /// Watch dead letter count and keep state updated.
  void _watchDeadLetterCount() {
    _deadLetterSub = _db.syncQueueDao.getDeadLetterCount().listen(
      (count) {
        if (!_disposed) {
          state = state.copyWith(deadLetterCount: count);
        }
      },
      onError: (e) {
        debugPrint('❌ [SyncEngine] Error watching dead letter count: $e');
      },
    );
  }

  /// Listen for online transitions to trigger sync.
  void _listenForConnectivity() {
    _ref.listen<AsyncValue<ConnectivityStatus>>(
      connectivityStatusProvider,
      (previous, next) {
        final prevStatus = previous?.valueOrNull;
        final newStatus = next.valueOrNull;
        if (prevStatus == ConnectivityStatus.offline &&
            newStatus == ConnectivityStatus.online) {
          debugPrint('📡 [SyncEngine] Back online — starting sync');
          syncNow();
        }
      },
    );
  }

  /// Retry entire sync pass up to 3 times with exponential backoff on failure.
  Future<void> syncWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await syncNow();
        return;
      } catch (e) {
        debugPrint(
            '⚠️ [SyncEngine] syncWithRetry attempt ${attempt + 1}/3 failed: $e');
        if (attempt < 2) {
          final delay = Duration(seconds: (1 << attempt) * 2);
          await Future.delayed(delay);
        }
      }
    }
  }

  /// Process all pending sync items.
  Future<void> syncNow() async {
    if (state.isSyncing) {
      debugPrint('⚠️ [SyncEngine] Already syncing, skipping');
      return;
    }

    // Check connectivity
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      debugPrint('📡 [SyncEngine] Offline, skipping sync');
      return;
    }

    state = state.copyWith(
      isSyncing: true,
      lastError: null,
      hasAuthError: false,
    );
    debugPrint('🔄 [SyncEngine] Starting sync...');

    try {
      // Recover stuck items before main loop
      final stuckReset =
          await _db.syncQueueDao.resetStuckInProgress(const Duration(minutes: 5));
      if (stuckReset > 0) {
        debugPrint(
            '🔄 [SyncEngine] Recovered $stuckReset stuck in_progress items');
      }

      while (!_disposed) {
        final items = await _db.syncQueueDao.getPendingItems(limit: 10);
        if (items.isEmpty) break;

        for (final item in items) {
          if (_disposed) break;
          await _processItem(item);
        }
      }

      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
      );
      debugPrint('✅ [SyncEngine] Sync completed');
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
        lastSyncError: e.toString(),
      );
      debugPrint('❌ [SyncEngine] Sync error: $e');
      _scheduleRetry();
    }
  }

  /// Process a single sync queue item.
  Future<void> _processItem(PendingSyncQueueData item) async {
    try {
      // Boost max retries for critical entity types
      if (_criticalEntityTypes.contains(item.entityType) &&
          item.maxRetries < _criticalMaxRetries) {
        await _db.syncQueueDao.updateMaxRetries(item.id, _criticalMaxRetries);
      }

      await _db.syncQueueDao.markInProgress(item.id);

      // Execute the API call
      final response = await _executeApiCall(
        httpMethod: item.httpMethod,
        endpoint: item.endpoint,
        payload: item.payload,
      );

      if (response) {
        await _db.syncQueueDao.markCompleted(item.id);
        debugPrint(
            '✅ [SyncEngine] Synced item ${item.id} (${item.entityType})');
      } else {
        throw Exception('API call returned unsuccessful response');
      }
    } catch (e) {
      final statusCode = _statusCodeOf(e);
      final errorStr = _formatError(e, statusCode);

      // Detect auth errors — surface so the UI can prompt re-login. Auth
      // failures stay in pending (a future token refresh may unblock them);
      // we set the flag but fall through to retry-count handling.
      if (statusCode == 401 || statusCode == 403) {
        state = state.copyWith(hasAuthError: true);
        debugPrint('🔐 [SyncEngine] Auth error detected for item ${item.id}');
      }

      // Permanent 4xx (except 401/403/408/429) means the payload is bad;
      // retrying it will fail identically. Move straight to dead-letter so
      // the user can see + edit/discard, instead of consuming retries that
      // can't possibly succeed (and keeping a red banner up for days).
      if (statusCode != null &&
          statusCode >= 400 &&
          statusCode < 500 &&
          statusCode != 401 &&
          statusCode != 403 &&
          statusCode != 408 &&
          statusCode != 429) {
        await _db.syncQueueDao.markFailed(item.id, errorStr);
        await _db.syncQueueDao.moveToDeadLetter(item.id);
        debugPrint(
            '💀 [SyncEngine] Item ${item.id} → dead-letter (HTTP $statusCode is non-retryable)');
        return;
      }

      final effectiveMaxRetries = _criticalEntityTypes.contains(item.entityType)
          ? _criticalMaxRetries
          : item.maxRetries;
      final newRetryCount = item.retryCount + 1;
      if (newRetryCount >= effectiveMaxRetries) {
        await _db.syncQueueDao.markFailed(item.id, errorStr);
        await _db.syncQueueDao.moveToDeadLetter(item.id);
        debugPrint(
            '💀 [SyncEngine] Item ${item.id} moved to dead letter after $effectiveMaxRetries retries');
      } else {
        await _db.syncQueueDao.markFailed(item.id, errorStr);
        debugPrint(
            '⚠️ [SyncEngine] Item ${item.id} failed (retry $newRetryCount/$effectiveMaxRetries): $e');
      }
    }
  }

  /// Extract HTTP status code from a thrown error, or null if not an HTTP
  /// response error. Inspects Dio response first so the classifier can
  /// reason about the actual server response instead of stringly-typed
  /// substring matching.
  int? _statusCodeOf(Object e) {
    if (e is DioException) return e.response?.statusCode;
    return null;
  }

  /// Persist an error message that includes the status code as a plain
  /// substring so `SyncErrorKind.classify()` (which still does string
  /// matching) categorizes it correctly when the dead-letter UI reads it.
  String _formatError(Object e, int? statusCode) {
    if (statusCode == null) return e.toString();
    final base = e.toString();
    return base.contains('$statusCode') ? base : 'HTTP $statusCode — $base';
  }

  /// Execute an API call based on the queued operation.
  Future<bool> _executeApiCall({
    required String httpMethod,
    required String endpoint,
    required String payload,
  }) async {
    // Dio's baseUrl already includes /api/v1. Strip a leading /api/v1 if any
    // historical queue rows persisted before the prefix bug fix still carry
    // the absolute path — otherwise we'd POST to /api/v1/api/v1/... and 404.
    var normalized = endpoint;
    if (normalized.startsWith('/api/v1/')) {
      normalized = normalized.substring('/api/v1'.length);
    } else if (normalized == '/api/v1') {
      normalized = '/';
    }

    try {
      switch (httpMethod.toUpperCase()) {
        case 'POST':
          await _apiClient.post(normalized, data: payload);
          return true;
        case 'PUT':
          await _apiClient.put(normalized, data: payload);
          return true;
        case 'PATCH':
          await _apiClient.patch(normalized, data: payload);
          return true;
        case 'DELETE':
          await _apiClient.delete(normalized);
          return true;
        default:
          debugPrint('⚠️ [SyncEngine] Unknown HTTP method: $httpMethod');
          return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Schedule a retry with exponential backoff and jitter.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final pendingCount = state.pendingCount;
    if (pendingCount == 0) return;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, ... max 60s
    final baseDelay = min(60, 1 * (1 << min(pendingCount, 6)));
    // Add 20% jitter
    final jitter = (baseDelay * 0.2 * Random().nextDouble()).toInt();
    final delaySeconds = baseDelay + jitter;

    debugPrint('🔄 [SyncEngine] Retrying in ${delaySeconds}s');
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_disposed) syncNow();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _deadLetterSub?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Main sync engine state provider.
final syncEngineProvider =
    StateNotifierProvider<SyncEngineNotifier, SyncState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return SyncEngineNotifier(db, apiClient, ref);
});

/// Convenience provider for pending sync count (for badges).
final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(syncEngineProvider).pendingCount;
});

/// Convenience provider for dead letter count (for failure badges).
final deadLetterCountProvider = Provider<int>((ref) {
  return ref.watch(syncEngineProvider).deadLetterCount;
});

/// Convenience provider for sync status.
final syncStateProvider = Provider<SyncState>((ref) {
  return ref.watch(syncEngineProvider);
});
