import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/offline_write_queue.dart';
import '../models/mood.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mood_history_repository.dart';

/// State for mood history
class MoodHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<MoodHistoryItem> checkins;
  final int totalCount;
  final bool hasMore;
  final MoodAnalyticsResponse? analytics;
  final MoodHistoryItem? todayCheckin;
  final int currentOffset;

  const MoodHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.checkins = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.analytics,
    this.todayCheckin,
    this.currentOffset = 0,
  });

  MoodHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<MoodHistoryItem>? checkins,
    int? totalCount,
    bool? hasMore,
    MoodAnalyticsResponse? analytics,
    MoodHistoryItem? todayCheckin,
    int? currentOffset,
    bool clearError = false,
    bool clearTodayCheckin = false,
  }) {
    return MoodHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      checkins: checkins ?? this.checkins,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      analytics: analytics ?? this.analytics,
      todayCheckin: clearTodayCheckin ? null : (todayCheckin ?? this.todayCheckin),
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

/// Provider for mood history state
final moodHistoryProvider =
    StateNotifierProvider<MoodHistoryNotifier, MoodHistoryState>((ref) {
  return MoodHistoryNotifier(
    ref.watch(moodHistoryRepositoryProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Notifier for mood history state management
class MoodHistoryNotifier extends StateNotifier<MoodHistoryState> {
  final MoodHistoryRepository _repository;
  final AuthRepository _authRepository;

  /// Part 4 (write→read consistency): disk-persisted offline queue of mood
  /// check-ins logged while the device had no connectivity. Flushed FIFO,
  /// idempotency-keyed, on the next connectivity-restored event so a rapid
  /// double-tap or a replayed write can never log the same mood twice.
  final OfflineWriteQueue _writeQueue = OfflineWriteQueue(feature: 'mood_checkin');

  /// Connectivity subscription that drains [_writeQueue] when the network
  /// returns. Bound lazily on the first [logMood] (we need a userId then).
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  /// Last user we logged a mood for — needed by the flush callback.
  String? _lastUserId;

  /// Re-entrancy guard so a connectivity event racing a manual log can't
  /// double-flush the same queued item.
  bool _isFlushing = false;

  MoodHistoryNotifier(this._repository, this._authRepository)
      : super(const MoodHistoryState());

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  /// Initialize data by loading history and analytics
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        // Load history, analytics, and today's check-in in parallel
        final results = await Future.wait([
          _repository.getMoodHistory(userId: user.id, limit: 30),
          _repository.getMoodAnalytics(userId: user.id, days: 30),
          _repository.getTodayMood(userId: user.id),
        ]);

        final historyResponse = results[0] as MoodHistoryResponse;
        final analytics = results[1] as MoodAnalyticsResponse?;
        final todayCheckin = results[2] as MoodHistoryItem?;

        state = state.copyWith(
          isLoading: false,
          checkins: historyResponse.checkins,
          totalCount: historyResponse.totalCount,
          hasMore: historyResponse.hasMore,
          analytics: analytics,
          todayCheckin: todayCheckin,
          currentOffset: historyResponse.checkins.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User not logged in',
        );
      }
    } catch (e) {
      debugPrint('Error initializing mood history: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more history (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final response = await _repository.getMoodHistory(
          userId: user.id,
          limit: 30,
          offset: state.currentOffset,
        );

        state = state.copyWith(
          isLoadingMore: false,
          checkins: [...state.checkins, ...response.checkins],
          totalCount: response.totalCount,
          hasMore: response.hasMore,
          currentOffset: state.currentOffset + response.checkins.length,
        );
      }
    } catch (e) {
      debugPrint('Error loading more mood history: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    state = state.copyWith(currentOffset: 0);
    await initialize();
  }

  /// Mark a workout as completed
  Future<bool> markWorkoutCompleted(String checkinId) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final success = await _repository.markWorkoutCompleted(
          userId: user.id,
          checkinId: checkinId,
        );

        if (success) {
          // Update local state
          final updatedCheckins = state.checkins.map((c) {
            if (c.id == checkinId) {
              return MoodHistoryItem(
                id: c.id,
                mood: c.mood,
                moodEmoji: c.moodEmoji,
                moodColor: c.moodColor,
                checkInTime: c.checkInTime,
                workoutGenerated: c.workoutGenerated,
                workoutCompleted: true,
                workout: c.workout,
                context: c.context,
              );
            }
            return c;
          }).toList();

          state = state.copyWith(checkins: updatedCheckins);
        }

        return success;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking workout completed: $e');
      return false;
    }
  }

  /// Whether the device currently has connectivity. Assumes online on error —
  /// the write itself will then fail-fast and roll back.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Lazily subscribe to connectivity so [_writeQueue] drains when the network
  /// returns. Bound on the first [logMood] (we need a userId).
  void _ensureConnectivityBound() {
    if (_connSub != null) return;
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        // Defer so the radio + DNS settle before hitting the API.
        Future.delayed(const Duration(milliseconds: 800), _flushQueue);
      }
    });
  }

  /// Drain the offline queue, replaying each mood check-in with its original
  /// idempotency key so the server de-dupes anything that already landed.
  Future<void> _flushQueue() async {
    final userId = _lastUserId;
    if (userId == null || _isFlushing) return;
    if (await _writeQueue.isEmpty(userId)) return;
    _isFlushing = true;
    try {
      final flushed = await _writeQueue.flush(
        userId: userId,
        sender: (body) async {
          try {
            await _repository.logMoodCheckin(
              userId: body['user_id'] as String,
              mood: body['mood'] as String,
              idempotencyKey: body['idempotency_key'] as String,
            );
            return true; // delivered — drop from queue
          } catch (e) {
            debugPrint('🙂 [Mood] queued flush item failed: $e');
            return false; // transient — keep it (and the rest) queued
          }
        },
      );
      if (flushed > 0) {
        // Reconcile optimistic check-ins with authoritative server rows.
        await refresh();
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Build a provisional [MoodHistoryItem] for an optimistic mood log. The id
  /// is the idempotency key so the row is stable + de-dupable until the server
  /// row replaces it on the next refresh.
  MoodHistoryItem _optimisticItem(Mood mood, String idempotencyKey) {
    return MoodHistoryItem(
      id: idempotencyKey,
      mood: mood.value,
      moodEmoji: mood.emoji,
      // Mood enum colorValue is 0xFFRRGGBB — render to a #RRGGBB hex string so
      // MoodHistoryItem.color decodes it the same way a server row would.
      moodColor:
          '#${(mood.colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      checkInTime: DateTime.now(),
    );
  }

  /// Log a mood check-in — optimistic, offline-safe (Part 4).
  ///
  ///  • The check-in is applied to provider state IMMEDIATELY (within one
  ///    frame), before the network write — so every surface that watches
  ///    [moodHistoryProvider] (Stats Mood tab, Mood History screen) reflects
  ///    it without a manual refresh. `todayCheckin` is also set so any
  ///    "today's mood" UI updates instantly.
  ///  • A client-generated idempotency key rides on the request body so a
  ///    rapid double-tap cannot create two `mood_checkins` rows.
  ///  • Offline → the write is persisted to the disk queue and flushed on the
  ///    next connectivity-restored event. The optimistic check-in stays.
  ///  • Online failure → the optimistic check-in is rolled back and the error
  ///    is rethrown so the caller surfaces a calm retry toast
  ///    ([[feedback_no_silent_fallbacks]] — never a fake success).
  ///
  /// Returns `true` once the optimistic apply has landed. Throws on an online
  /// write failure (after rolling back).
  Future<bool> logMood(Mood mood) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) {
      throw StateError('Cannot log mood — no signed-in user');
    }
    _lastUserId = user.id;
    _ensureConnectivityBound();

    final idempotencyKey = OfflineWriteQueue.idempotencyKey('mood');

    // ---- Optimistic apply -------------------------------------------------
    // Snapshot for rollback, then prepend the provisional check-in and set it
    // as today's check-in.
    final snapshot = state;
    final optimisticItem = _optimisticItem(mood, idempotencyKey);
    state = state.copyWith(
      clearError: true,
      checkins: [optimisticItem, ...state.checkins],
      totalCount: state.totalCount + 1,
      todayCheckin: optimisticItem,
    );

    // ---- Offline → queue and keep the optimistic check-in -----------------
    if (!await _isOnline()) {
      await _writeQueue.enqueue(
        userId: user.id,
        body: {
          'user_id': user.id,
          'mood': mood.value,
          'idempotency_key': idempotencyKey,
        },
      );
      debugPrint('🙂 [Mood] offline — ${mood.value} queued ($idempotencyKey)');
      return true;
    }

    // ---- Online → write through, roll back on failure ---------------------
    try {
      await _repository.logMoodCheckin(
        userId: user.id,
        mood: mood.value,
        idempotencyKey: idempotencyKey,
      );
      return true;
    } catch (e) {
      // Online but the write failed — roll back so the UI never shows a mood
      // that was not persisted.
      state = snapshot.copyWith(
        error: "Couldn't save your mood. We'll retry when you're back online.",
      );
      debugPrint('🙂 [Mood] optimistic write rolled back: $e');
      rethrow; // caller shows a calm retry toast
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for mood analytics only (cached)
final moodAnalyticsProvider = FutureProvider<MoodAnalyticsResponse?>((ref) async {
  final repository = ref.watch(moodHistoryRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user != null) {
    return await repository.getMoodAnalytics(userId: user.id, days: 30);
  }
  return null;
});

/// Provider for today's mood check-in
final todayMoodCheckinProvider = FutureProvider<MoodHistoryItem?>((ref) async {
  final repository = ref.watch(moodHistoryRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user != null) {
    return await repository.getTodayMood(userId: user.id);
  }
  return null;
});
