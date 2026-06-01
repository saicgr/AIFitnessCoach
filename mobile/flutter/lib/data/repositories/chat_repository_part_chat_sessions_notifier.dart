part of 'chat_repository.dart';

/// Lists "Ask Coach" chat sessions with instant cache load + silent refresh.
///
/// Per feedback_instant_data + project_tab_instant_perf: paint the last-known
/// list on the SAME frame (in-memory cache, else a raced disk read), then
/// revalidate from the server in the background and swap in the fresh list.
/// A loading shimmer appears only on a true cold start (no cache anywhere).
/// Never shows a pull-to-refresh control — the screen calls [refresh] silently.
///
/// Mirrors the proven `todayWorkoutProvider` pattern (static in-memory cache
/// surviving provider invalidation + parallel disk/network race).
class ChatSessionsNotifier
    extends StateNotifier<AsyncValue<List<ChatSession>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;

  /// STATIC in-memory cache — survives provider invalidation (auth token
  /// refresh recreates the notifier) so reopening "Ask Coach" paints instantly
  /// with zero disk I/O. Scoped to [_inMemoryOwnerUserId]; wiped on real
  /// account change by [resetInMemoryCache] (called from the provider) so one
  /// user never sees another's conversations.
  static List<ChatSession>? _inMemoryCache;
  static String? _inMemoryOwnerUserId;

  /// The user_id the static in-memory cache currently belongs to.
  static String? get inMemoryOwnerUserId => _inMemoryOwnerUserId;

  /// Wipe the in-memory cache on a real user-id change (sign-out → sign-in).
  /// Sets the new owner so the next paint can't inherit stale cross-user data.
  static void resetInMemoryCache(String newOwnerUserId) {
    _inMemoryCache = null;
    _inMemoryOwnerUserId = newOwnerUserId;
  }

  ChatSessionsNotifier(this._repository, this._apiClient)
      : super(
          // Instant paint from in-memory cache when present, else cold loading.
          _inMemoryCache != null
              ? AsyncValue.data(_inMemoryCache!)
              : const AsyncValue.loading(),
        ) {
    _restoreFromCacheThenRefresh();
  }

  bool _includeArchived = false;
  String _query = '';
  Future<void>? _inFlight;

  /// Current search query (mirrors what the screen typed). Empty = no filter.
  String get query => _query;
  bool get includeArchived => _includeArchived;

  /// Decode cached/raw JSON into sessions, skipping any malformed entry so a
  /// schema drift in one cached row can never crash the whole list.
  List<ChatSession> _decodeSessions(List<Map<String, dynamic>> raw) {
    final out = <ChatSession>[];
    for (final j in raw) {
      try {
        out.add(ChatSession.fromJson(j));
      } catch (e) {
        debugPrint('⚠️ [ChatSessions] skipping malformed cached session: $e');
      }
    }
    return out;
  }

  Future<void> _restoreFromCacheThenRefresh() async {
    final userId = await _apiClient.getUserId();
    if (userId == null || !mounted) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    // Already painted from in-memory cache for THIS user → just revalidate.
    if (_inMemoryCache != null && _inMemoryOwnerUserId == userId) {
      await refresh();
      return;
    }

    // Race: fire the network refresh immediately, read the disk cache in
    // PARALLEL, and paint whichever arrives first. The disk read is only
    // allowed to paint if the network hasn't already delivered fresh data.
    final refreshFuture = refresh();
    try {
      final cached = await DataCacheService.instance.getCachedList(
        DataCacheService.chatSessionsKey,
        userId: userId,
        // Stale-while-revalidate: show last-known sessions even past TTL —
        // the refresh already in flight will swap in fresh data.
        returnExpiredOnMiss: true,
      );
      if (cached != null &&
          cached.isNotEmpty &&
          mounted &&
          state.valueOrNull == null) {
        final sessions = _decodeSessions(cached);
        if (sessions.isNotEmpty) {
          _inMemoryCache = sessions;
          _inMemoryOwnerUserId = userId;
          state = AsyncValue.data(sessions);
        }
      }
    } catch (e) {
      debugPrint('❌ [ChatSessions] cache restore failed: $e');
    }
    await refreshFuture;
  }

  /// Re-fetch the session list from the server using the current query +
  /// archived filter. Keeps showing existing data while refreshing so the
  /// list never flashes empty.
  Future<void> refresh() {
    if (_inFlight != null) return _inFlight!;
    _inFlight = _doRefresh();
    return _inFlight!;
  }

  Future<void> _doRefresh() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null || !mounted) return;
      // Show a spinner ONLY on a true cold start (nothing painted, no cache).
      if (state.valueOrNull == null && _inMemoryCache == null) {
        state = const AsyncValue.loading();
      }
      final sessions = await _repository.listSessions(
        q: _query,
        includeArchived: _includeArchived,
      );
      if (!mounted) return;
      state = AsyncValue.data(sessions);
      // Only cache the unfiltered, non-archived list so the instant-paint on
      // next open reflects the default view.
      if (_query.isEmpty && !_includeArchived) {
        _inMemoryCache = sessions;
        _inMemoryOwnerUserId = userId;
        await DataCacheService.instance.cacheList(
          DataCacheService.chatSessionsKey,
          sessions.map((s) => s.toJson()).toList(),
          userId: userId,
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      // Keep cached data visible on error; only surface error when empty.
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      } else {
        debugPrint('⚠️ [ChatSessions] refresh failed, keeping cached: $e');
      }
    } finally {
      _inFlight = null;
    }
  }

  /// Set the search query (debounced by the screen) and refresh.
  Future<void> setQuery(String q) {
    final next = q.trim();
    if (next == _query) return Future.value();
    _query = next;
    return refresh();
  }

  /// Toggle whether archived sessions are included, then refresh.
  Future<void> setIncludeArchived(bool value) {
    if (value == _includeArchived) return Future.value();
    _includeArchived = value;
    return refresh();
  }

  /// Rename a session and reflect it locally without a full re-fetch.
  Future<void> rename(String sessionId, String title) async {
    final updated = await _repository.renameSession(sessionId, title);
    _replace(updated);
  }

  /// Archive / unarchive a session.
  Future<void> archive(String sessionId, bool isArchived) async {
    final updated = await _repository.archiveSession(sessionId, isArchived);
    if (isArchived && !_includeArchived) {
      // Falls out of the current (non-archived) view — drop it locally.
      _remove(sessionId);
    } else {
      _replace(updated);
    }
  }

  /// Delete a session (cascades messages server-side).
  Future<void> delete(String sessionId) async {
    await _repository.deleteSession(sessionId);
    _remove(sessionId);
  }

  void _replace(ChatSession session) {
    final current = state.valueOrNull ?? const <ChatSession>[];
    final next = current
        .map((s) => s.id == session.id ? session : s)
        .toList(growable: false);
    state = AsyncValue.data(next);
    _syncInMemory(next);
  }

  void _remove(String sessionId) {
    final current = state.valueOrNull ?? const <ChatSession>[];
    final next = current.where((s) => s.id != sessionId).toList(growable: false);
    state = AsyncValue.data(next);
    _syncInMemory(next);
  }

  /// Keep the static in-memory cache in step with optimistic local mutations
  /// (rename/archive/delete) so the next instant-paint isn't stale.
  void _syncInMemory(List<ChatSession> next) {
    if (_query.isEmpty && !_includeArchived && _inMemoryOwnerUserId != null) {
      _inMemoryCache = next;
    }
  }
}
