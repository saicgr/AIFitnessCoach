part of 'chat_repository.dart';

/// Lists "Ask Coach" chat sessions with instant cache load + silent refresh.
///
/// Per feedback_instant_data: paint cached sessions synchronously-ish (first
/// disk read), then refresh from the server in the background and swap in the
/// fresh list. Never shows a pull-to-refresh control — the screen calls
/// [refresh] silently when it opens.
class ChatSessionsNotifier
    extends StateNotifier<AsyncValue<List<ChatSession>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;

  ChatSessionsNotifier(this._repository, this._apiClient)
      : super(const AsyncValue.loading()) {
    _restoreFromCacheThenRefresh();
  }

  /// Disk cache key for the (non-archived) session list.
  static String _cacheKey(String userId) => 'cache_chat_sessions_$userId';

  bool _includeArchived = false;
  String _query = '';
  Future<void>? _inFlight;

  /// Current search query (mirrors what the screen typed). Empty = no filter.
  String get query => _query;
  bool get includeArchived => _includeArchived;

  Future<void> _restoreFromCacheThenRefresh() async {
    final userId = await _apiClient.getUserId();
    if (userId == null || !mounted) {
      state = const AsyncValue.data([]);
      return;
    }
    // 1. Instant paint from cache (no q filter — cache holds the full list).
    try {
      final cached =
          await DataCacheService.instance.getCachedList(_cacheKey(userId));
      if (cached != null && cached.isNotEmpty && mounted) {
        final sessions =
            cached.map((j) => ChatSession.fromJson(j)).toList();
        state = AsyncValue.data(sessions);
      }
    } catch (e) {
      debugPrint('❌ [ChatSessions] cache restore failed: $e');
    }
    // 2. Silent background refresh.
    await refresh();
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
      // Show a spinner only on a truly cold start (no data yet).
      if (state.valueOrNull == null) {
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
        await DataCacheService.instance.cacheList(
          _cacheKey(userId),
          sessions.map((s) => s.toJson()).toList(),
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
  }

  void _remove(String sessionId) {
    final current = state.valueOrNull ?? const <ChatSession>[];
    state = AsyncValue.data(
        current.where((s) => s.id != sessionId).toList(growable: false));
  }
}
