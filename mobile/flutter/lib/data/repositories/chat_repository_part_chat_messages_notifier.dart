part of 'chat_repository.dart';


/// Snapshot of the assistant bubble that is currently streaming token-by-token.
///
/// While a reply streams, the partial text is held HERE — not in the main
/// `state` list — so that only the last bubble (which subscribes to
/// [ChatMessagesNotifier.streamingBubble]) rebuilds per token. The full
/// `ListView` is never rebuilt at token cadence (C4).
///
/// On `done`/`error` the bubble is reconciled into `state` and the notifier
/// is reset to `null`, which removes the live bubble and shows the committed
/// (or failed) message instead.
class StreamingBubbleState {
  /// Server-issued message UUID once the `done` event lands; null while
  /// tokens are still arriving (the bubble has no stable id yet).
  final String? messageId;

  /// Partial reply text accumulated from `delta` chunks so far.
  final String content;

  /// ISO8601 creation time — assigned once when streaming starts so the
  /// bubble sorts correctly when it is finally committed to `state`.
  final String createdAt;

  /// Coach persona that owns this reply (for avatar/identity in the bubble).
  final String? coachPersonaId;

  /// True once the stream has dropped mid-reply. The partial [content] is
  /// KEPT (C2) and the bubble shows a retry affordance instead of vanishing.
  final bool dropped;

  const StreamingBubbleState({
    this.messageId,
    required this.content,
    required this.createdAt,
    this.coachPersonaId,
    this.dropped = false,
  });

  StreamingBubbleState copyWith({
    String? messageId,
    String? content,
    bool? dropped,
  }) {
    return StreamingBubbleState(
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      createdAt: createdAt,
      coachPersonaId: coachPersonaId,
      dropped: dropped ?? this.dropped,
    );
  }
}


/// Chat messages state notifier
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;
  final WorkoutsNotifier _workoutsNotifier;
  final WorkoutRepository _workoutRepository;
  final User? _user;
  final ThemeModeNotifier _themeNotifier;
  final GoRouter _router;
  final HydrationNotifier _hydrationNotifier;
  final NutritionNotifier _nutritionNotifier;
  final AISettings Function() _getAISettings; // Callback to get fresh settings
  final void Function(bool) _setAIGenerating; // Callback to set AI generating state
  final String Function() _getUnifiedContext; // Callback to get unified fasting/nutrition/workout context
  final OfflineCoachService _offlineCoach;
  final bool Function() _isOnline;
  final SoundPreferencesNotifier Function() _getSoundPrefs;
  final AudioPreferencesNotifier Function() _getAudioPrefs;
  // Refresh /today after AI-driven workout completions so the home carousel +
  // week-strip checkmark flip immediately, instead of staying on the
  // pre-completion snapshot until the next manual refresh.
  final void Function() _refreshTodayWorkout;
  // Phase F — invalidates the cycle providers after a cycle-agent action so
  // a live Cycle screen / home card repaints with the new data.
  final void Function() _refreshCycleData;
  // Captured provider container ref — used by _handleSettingChange to read the
  // many setting notifiers (notifications, nutrition UI, accent, accessibility,
  // units, etc.) lazily at action time. Read-only at action time; never
  // retains a subscription, matching the getSoundPrefs/getAudioPrefs pattern.
  final Ref _ref;
  bool _isLoading = false;
  Future<void>? _loadHistoryFuture;

  // Pagination state (#16)
  int _currentOffset = 0;
  bool _hasMoreMessages = true;
  // In-flight guard for loadOlderMessages — scroll listeners can fire dozens
  // of times per second during a fling, so we dedupe by future to avoid
  // spamming GET /chat/history and tripping the 30-req/min rate limit.
  Future<void>? _loadOlderFuture;
  // Gate: loadOlderMessages must not fire until the initial loadHistory has
  // completed. Otherwise a user who scrolls during cold-start races the
  // initial fetch (both hit /chat/history with different pagination) and the
  // second reply overwrites the first. Flipped true when _doLoadHistory's
  // fresh API fetch settles (success OR error — either way pagination owns
  // the offset cursor from that point on).
  bool _initialHistoryLoaded = false;

  // Offline message queue (#31)
  final List<String> _pendingOfflineMessages = [];

  // ── Streaming reply state (Part 5 — C4) ────────────────────────────────
  // The token-by-token assistant bubble lives in this ValueNotifier while it
  // streams. The chat ListView renders a single bubble bound to this
  // listenable as its newest item, so per-token updates repaint ONLY that
  // bubble — never the whole list. `null` = no reply currently streaming.
  final ValueNotifier<StreamingBubbleState?> streamingBubble =
      ValueNotifier<StreamingBubbleState?>(null);

  /// Last partial text persisted to cache during a stream, used to throttle
  /// cache writes (C2) so we don't hammer SharedPreferences on every token.
  DateTime _lastPartialPersist = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether a streaming reply is currently in flight (true between the first
  /// token and the terminal done/error event, or until a drop is handled).
  bool get isStreaming => streamingBubble.value != null;

  // Fix #10 — one-time prune migration runs on first loadHistory of the
  // notifier's lifetime. Guarded by SharedPreferences claim so it never
  // re-runs across cold starts (or across concurrent notifier rebuilds).
  bool _pruneAttemptedThisSession = false;

  /// Heuristic: should the candidate assistant message be treated as an
  /// auto-fired coach tip? The model has no `source` / `metadata` field
  /// today, so we fall back to a content-pattern check for the canonical
  /// coach-persona prefix ("Listen up,…", "Yep, that's right,…", etc.)
  /// emitted by the active-workout coach-tip pipeline.
  bool _looksLikeAutoCoachTip(ChatMessage m) {
    if (m.role != 'assistant') return false;
    final content = m.content.trimLeft();
    if (content.isEmpty) return false;
    // Coach-persona greeting prefixes pulled from data/models/coach_persona.dart
    // and the auto-tip pipeline. Conservative; better to under-tag than to
    // wrongly drop a real reply.
    const prefixes = <String>[
      'Listen up',
      "Yep, that's right",
      'Yep that\'s right',
    ];
    for (final p in prefixes) {
      if (content.startsWith(p)) return true;
    }
    return false;
  }

  /// Fix #10 dedup gate. Returns true if the message should be APPENDED to
  /// chat state, false if it should be skipped. Skips:
  ///   - Auto-coach-tip messages when the user has not opted in to keeping
  ///     them in chat history.
  ///   - Long (> 80 char) assistant messages that are near-duplicates of one
  ///     of the last 3 assistant bubbles.
  /// User messages are NEVER skipped.
  Future<bool> _shouldAppendAssistantMessage(ChatMessage candidate) async {
    if (candidate.role != 'assistant') return true;

    // 1) Coach-tip opt-in gate.
    if (_looksLikeAutoCoachTip(candidate)) {
      final saveTips = await ExerciseTipService.shouldSaveCoachTipsToChat();
      if (!saveTips) {
        debugPrint(
          '🛑 [Chat] Skipping auto-coach-tip append (opt-in disabled). '
          'Tip remains visible as inline banner only.',
        );
        return false;
      }
    }

    // 2) Levenshtein dedup gate.
    final content = candidate.content;
    if (content.length > kCoachTipDedupMinChars) {
      final recent = (state.valueOrNull ?? const <ChatMessage>[])
          .where((m) => m.role == 'assistant')
          .map((m) => m.content)
          .toList();
      if (ExerciseTipService.isNearDuplicateOfRecent(content, recent)) {
        debugPrint(
          '🛑 [Chat] Skipping near-duplicate assistant append '
          '(Levenshtein > $kCoachTipDedupSimilarityThreshold against last '
          '$kCoachTipDedupWindow assistant messages).',
        );
        return false;
      }
    }
    return true;
  }

  /// Fix #10 one-time prune migration. Runs ONCE per device (idempotent via
  /// SharedPreferences claim flag). Walks the last 30 days of assistant
  /// messages and deletes the LATER of every Levenshtein-near-duplicate pair
  /// (similarity > 0.85). Only assistant rows that look like auto-coach-tips
  /// are eligible for deletion — never user messages or normal replies.
  ///
  /// Failure-safe: any exception during prune leaves the claim flag set
  /// (avoiding re-runs that could race with future state) but logs the error.
  Future<void> _runOneTimeCoachTipPrune() async {
    if (_pruneAttemptedThisSession) return;
    _pruneAttemptedThisSession = true;

    final shouldRun = await ExerciseTipService.claimPruneCoachDuplicatesV1();
    if (!shouldRun) {
      debugPrint('💡 [Chat] Coach-tip prune already complete — skipping');
      return;
    }

    try {
      final messages = state.valueOrNull ?? const <ChatMessage>[];
      if (messages.isEmpty) return;

      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      // Walk chronologically; identify clusters of assistant rows where
      // consecutive content has similarity > 0.85, and the later candidate
      // looks like an auto-coach-tip (heuristic).
      final toDeleteIds = <String>{};
      final toDeleteCreatedAt = <String>{};
      ChatMessage? prevAsst;
      for (final m in messages) {
        if (m.role != 'assistant') continue;
        final created = m.timestamp;
        if (created != null && created.isBefore(cutoff)) {
          prevAsst = m;
          continue;
        }
        if (prevAsst != null) {
          final prevText = prevAsst.content;
          if (prevText.length > kCoachTipDedupMinChars &&
              m.content.length > kCoachTipDedupMinChars) {
            // Reuse public dedup helper — it scans a list, so wrap prev as a
            // single-element window.
            final isDup =
                ExerciseTipService.isNearDuplicateOfRecent(m.content, [prevText]);
            // Only delete the LATER message, and only when it looks like an
            // auto-coach-tip — never strip a real user-initiated reply.
            if (isDup && _looksLikeAutoCoachTip(m)) {
              if (m.id != null && m.id!.isNotEmpty) {
                toDeleteIds.add(m.id!);
              } else if (m.createdAt != null) {
                toDeleteCreatedAt.add(m.createdAt!);
              }
              // Keep prevAsst as the cluster anchor — fall through.
              continue;
            }
          }
        }
        prevAsst = m;
      }

      if (toDeleteIds.isEmpty && toDeleteCreatedAt.isEmpty) {
        debugPrint('💡 [Chat] Coach-tip prune: no duplicates found');
        return;
      }

      // Apply local state delete first so the UI reflects immediately.
      final pruned = messages
          .where((m) =>
              !(m.role == 'assistant' &&
                  ((m.id != null && toDeleteIds.contains(m.id)) ||
                      (m.id == null &&
                          m.createdAt != null &&
                          toDeleteCreatedAt.contains(m.createdAt)))))
          .toList();
      state = AsyncValue.data(pruned);
      debugPrint(
        '🧹 [Chat] Coach-tip prune removed '
        '${messages.length - pruned.length} duplicate assistant rows '
        '(${toDeleteIds.length} by id, ${toDeleteCreatedAt.length} by ts).',
      );

      // Persist to backend best-effort. Failures here don't unset the claim
      // — local state is already pruned and replays from cache will reflect
      // the new shape. Server-side prune is durability.
      for (final id in toDeleteIds) {
        try {
          await _repository.deleteMessage(id);
        } catch (e) {
          debugPrint('⚠️ [Chat] Coach-tip prune: deleteMessage($id) failed: $e');
        }
      }

      // Update cache.
      final userId = await _apiClient.getUserId();
      if (userId != null) {
        await _saveToCache(userId, pruned);
      }
    } catch (e, st) {
      debugPrint('❌ [Chat] Coach-tip prune failed: $e');
      debugPrint('❌ [Chat] Stack: $st');
      // Note: claim flag is intentionally LEFT SET so we don't keep retrying
      // on every cold start. Fixing a botched prune is a manual reset.
    }
  }

  /// Keywords that indicate user wants a quick workout (mirrors backend)
  static const _quickWorkoutKeywords = [
    'quick workout', 'short workout', 'fast workout',
    'quick exercise', 'something quick', 'something fast',
    '15 minute', '10 minute', '20 minute', '5 minute', '30 minute',
    'give me a quick', 'create a quick', 'need a quick', 'want a quick',
    'no time', 'short on time', 'in a hurry',
    'generate a workout', 'create a workout', 'make me a workout',
    'new workout', 'different workout',
    'cardio workout', 'hiit workout', 'bodyweight workout',
    'upper body workout', 'lower body workout', 'core workout',
    'leg workout', 'arm workout', 'chest workout', 'back workout',
    // Sport-specific workout types
    'boxing workout', 'boxing training', 'boxer workout',
    'hyrox workout', 'hyrox training', 'train for hyrox',
    'crossfit workout', 'crossfit wod', 'wod',
    'mma workout', 'mma training', 'martial arts workout', 'fighter workout',
    'tabata workout', 'interval workout', 'circuit workout',
    'strength workout', 'strength training',
    'endurance workout', 'endurance training',
    'flexibility workout', 'stretching workout', 'yoga workout',
    'mobility workout', 'mobility training',
    // Sport mentions
    'want to box', 'want to be a boxer', 'train like a boxer',
    'want to do hyrox', 'hyrox athlete',
    'want to do crossfit', 'train like crossfit',
    'train like a fighter', 'want to fight',
  ];

  ChatMessagesNotifier(this._repository, this._apiClient, this._workoutsNotifier, this._workoutRepository, this._user, this._themeNotifier, this._router, this._hydrationNotifier, this._nutritionNotifier, this._getAISettings, this._setAIGenerating, this._getUnifiedContext, this._offlineCoach, this._isOnline, this._getSoundPrefs, this._getAudioPrefs, this._refreshTodayWorkout, this._refreshCycleData, this._ref)
      : super(const AsyncValue.data([])) {
    _instances.add(this);
    _restoreFromCache();
  }

  /// Live-instance registry so [closeAllStreams] (a static, called from
  /// AuthRepository sign-out) can reach the running notifier and tear
  /// down any in-flight chat streams + flush the message list. Today the
  /// notifier doesn't hold a long-lived SSE / WebSocket subscription —
  /// chat replies are short-lived `Dio.post` calls — but routing the
  /// teardown through here gives us a single chokepoint for the day a
  /// streaming reply is added so we don't have to re-thread sign-out
  /// awareness through every call site.
  static final Set<ChatMessagesNotifier> _instances = {};

  /// Cancel any in-flight chat streams on sign-out and reset the local
  /// message list so the previous user's last conversation can't briefly
  /// flash before the next user's history loads. Safe to call even if no
  /// notifier is currently constructed (no-op).
  static void closeAllStreams() {
    for (final n in _instances.toList()) {
      if (!n.mounted) continue;
      // Reset back to the same initial state the constructor uses so a
      // future _restoreFromCache() (after sign-in) starts from a clean
      // slate. We deliberately do NOT touch cache here — DataCacheService
      // is wiped by the orchestrator immediately after this returns.
      n.state = const AsyncValue.data([]);
      n._loadHistoryFuture = null;
      n._loadOlderFuture = null;
      n._currentOffset = 0;
      n._hasMoreMessages = true;
      n._initialHistoryLoaded = false;
      n._currentSessionId = null;
      n._pendingOfflineMessages.clear();
      // Drop any in-flight streaming bubble so the previous user's partial
      // reply can't flash before the next user's history loads.
      n.streamingBubble.value = null;
    }
  }

  /// Restore messages from cache on notifier recreation to prevent empty flash
  Future<void> _restoreFromCache() async {
    final userId = await _apiClient.getUserId();
    if (userId == null || !mounted) return;
    final cached = await _loadFromCache(userId);
    if (mounted && cached.isNotEmpty && (state.valueOrNull?.isEmpty ?? true)) {
      state = AsyncValue.data(cached);
    }
  }

  bool get isLoading => _isLoading;

  /// Whether more messages are available for pagination (#16)
  bool get hasMoreMessages => _hasMoreMessages;

  /// Update the status of a specific message in the current state (#14)
  void _updateMessageStatus(ChatMessage target, MessageStatus newStatus) {
    final messages = state.valueOrNull;
    if (messages == null) return;
    final updated = messages.map((m) {
      if (m.createdAt == target.createdAt && m.role == target.role && m.content == target.content) {
        return m.copyWith(status: newStatus);
      }
      return m;
    }).toList();
    state = AsyncValue.data(updated);
  }

  // ── Session scoping (Ask Coach conversation threads) ──────────────────
  // The active session id. null = a brand-new, not-yet-sent chat — the
  // session is created server-side on the first /send and ADOPTED here.
  // Kept in lockstep with [currentChatSessionProvider]; the notifier is NOT
  // rebuilt when it changes so the message list survives a switch.
  String? _currentSessionId;

  /// Callback into the provider tree so the notifier can publish an adopted /
  /// switched session id to [currentChatSessionProvider] and refresh the
  /// sessions list. Wired by the provider factory.
  void Function(String? sessionId)? _onSessionChanged;
  void Function()? _refreshSessions;

  /// The active session id (null = brand-new unsent chat).
  String? get currentSessionId => _currentSessionId;

  /// Build the cache key for chat history for a given user, scoped to the
  /// active session. A null session (brand-new chat) uses the 'current'
  /// suffix so its draft list doesn't collide with a real session's cache.
  static String _cacheKeyFor(String userId, String? sessionId) =>
      'cache_chat_history_${userId}_${sessionId ?? 'current'}';

  /// Instance helper: cache key for the CURRENT session.
  String _cacheKey(String userId) => _cacheKeyFor(userId, _currentSessionId);

  /// In-memory mirror key (user + session scoped).
  String _memKey(String userId) => '$userId::${_currentSessionId ?? 'current'}';

  /// Module-level in-memory mirror of the disk cache. Survives provider
  /// recreation so opening /chat for the second (or fiftieth) time in a
  /// session renders cached messages SYNCHRONOUSLY — no white-screen-with-
  /// dot wait while we await SharedPreferences (user complaint 2026-05-25:
  /// "previous messages take time to load"). Disk is still the source of
  /// truth and re-hydrates this map on the FIRST load per cold start.
  static final Map<String, List<ChatMessage>> _memCache = {};

  /// Synchronous accessor for the in-memory cache. Returns null when nothing
  /// has been hydrated yet for [userId] (first cold-start of the app or
  /// first-ever chat view). Used by [loadHistory] to paint immediately.
  /// Session-scoped via [_memKey].
  List<ChatMessage>? memCacheFor(String userId) => _memCache[_memKey(userId)];

  /// Load cached chat messages from DataCacheService. Populates the in-memory
  /// mirror so subsequent calls (within the session) can skip the disk read.
  Future<List<ChatMessage>> _loadFromCache(String userId) async {
    final memKey = _memKey(userId);
    // Fast path — in-memory hit, no disk awaits.
    final mem = _memCache[memKey];
    if (mem != null && mem.isNotEmpty) {
      debugPrint('⚡ [Chat] Loaded ${mem.length} messages from in-memory cache');
      return mem;
    }
    try {
      final cached = await DataCacheService.instance.getCachedList(_cacheKey(userId));
      if (cached != null && cached.isNotEmpty) {
        final messages = cached.map((json) => ChatMessage.fromJson(json)).toList();
        _memCache[memKey] = messages;
        debugPrint('💾 [Chat] Loaded ${messages.length} messages from disk cache');
        return messages;
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error loading from cache: $e');
    }
    return [];
  }

  /// Save chat messages to DataCacheService (capped at 200 messages)
  Future<void> _saveToCache(String userId, List<ChatMessage> messages) async {
    try {
      // Limit cache to last 200 messages (#32)
      final trimmed = messages.length > 200
          ? messages.sublist(messages.length - 200)
          : messages;
      // Keep the in-memory mirror in sync — every save updates the fast path
      // so the next screen entry is instant.
      _memCache[_memKey(userId)] = List<ChatMessage>.unmodifiable(trimmed);
      final jsonList = trimmed.map((m) => m.toJson()).toList();
      await DataCacheService.instance.cacheList(_cacheKey(userId), jsonList);
      debugPrint('💾 [Chat] Saved ${trimmed.length} messages to cache');
    } catch (e) {
      debugPrint('❌ [Chat] Error saving to cache: $e');
    }
  }

  /// Load chat history with cache-first pattern
  /// If force is false, only loads if there are no messages yet
  /// Concurrent calls are deduplicated — callers await the same in-flight request.
  Future<void> loadHistory({bool force = false}) {
    // Skip loading if we already have messages and not forcing
    final currentMessages = state.valueOrNull;
    if (!force && currentMessages != null && currentMessages.isNotEmpty) {
      debugPrint('🔍 [Chat] Skipping history load - already have ${currentMessages.length} messages');
      return Future.value();
    }

    // Dedup: if a load is already in-flight, piggyback on it
    if (_loadHistoryFuture != null && !force) {
      debugPrint('🔍 [Chat] Dedup - reusing in-flight history load');
      return _loadHistoryFuture!;
    }

    _loadHistoryFuture = _doLoadHistory(force: force);
    return _loadHistoryFuture!;
  }

  Future<void> _doLoadHistory({bool force = false}) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null || !mounted) return;

      // 0. Synchronous warm-paint from the module-level in-memory mirror so
      //    the screen never sees AsyncValue.loading when there is data we
      //    already have. Awaiting the disk read still happens below — but
      //    on every entry after the first cold-start hit the user sees
      //    messages instantly.
      final memCached = _memCache[_memKey(userId)];
      if (memCached != null && memCached.isNotEmpty && mounted) {
        state = AsyncValue.data(memCached);
      }

      // 1. Load from cache first and show immediately
      final cachedMessages = await _loadFromCache(userId);
      if (!mounted) return;
      if (cachedMessages.isNotEmpty) {
        state = AsyncValue.data(cachedMessages);
        debugPrint('🔍 [Chat] Showing ${cachedMessages.length} cached messages while fetching fresh data');
      } else {
        state = const AsyncValue.loading();
      }

      // 2. Fetch fresh data from API in background.
      //    - A null session = a brand-new, not-yet-sent chat → start empty
      //      (the open/empty state); no server round-trip and no session
      //      exists yet to fetch from.
      //    - A set session → fetch THAT session's messages.
      if (_currentSessionId == null) {
        if (!mounted) return;
        if (cachedMessages.isEmpty) {
          state = const AsyncValue.data([]);
        }
        return;
      }
      try {
        final messages =
            await _repository.getSessionMessages(_currentSessionId!);
        if (!mounted) return;

        // If sendMessage is in-flight, don't replace state — the send
        // owns state and will produce the authoritative version when done.
        if (_isLoading) {
          debugPrint('⚠️ [Chat] Skipping history state replacement — sendMessage in-flight');
          await _saveToCache(userId, messages);
          return;
        }

        // Defense-in-depth: if a freshly-sent assistant bubble landed in
        // local state with a server-issued id BEFORE the history fetch
        // returned, the fetched list will contain the same row by id.
        // Replacing state outright is fine — the row is single-sourced
        // by id. But if the fetched list is missing the most-recent
        // message (replication lag), keep any local-only messages whose
        // id is not in the fetched set so the user doesn't see their
        // bubble vanish and reappear. The send path's dedup-by-id has
        // already prevented double-appending.
        final fetchedIds = messages.map((m) => m.id).whereType<String>().toSet();
        final localOnly = (state.valueOrNull ?? [])
            .where((m) => m.id != null && !fetchedIds.contains(m.id))
            .toList();
        final mergedMessages = localOnly.isEmpty ? messages : [...messages, ...localOnly];
        state = AsyncValue.data(mergedMessages);
        _currentOffset = messages.length;
        // If initial load returned fewer than page size, no older messages exist
        if (messages.length < 50) {
          _hasMoreMessages = false;
        }
        // 3. Update cache with fresh data
        await _saveToCache(userId, messages);
      } catch (e, st) {
        if (!mounted) return;
        // If we have cached data, keep showing it instead of error
        if (cachedMessages.isNotEmpty) {
          debugPrint('⚠️ [Chat] API fetch failed, keeping cached data: $e');
        } else {
          state = AsyncValue.error(e, st);
        }
      }
    } finally {
      _loadHistoryFuture = null;
      // Open the gate for loadOlderMessages once the initial history fetch
      // has settled (regardless of outcome). Before this point, the initial
      // fetch owns the offset cursor; after, pagination can extend it.
      _initialHistoryLoaded = true;
      // Fix #10 — kick off the one-time coach-tip prune migration. Runs
      // exactly once per device (idempotent via SharedPreferences claim).
      // Fire-and-forget so loadHistory's caller isn't blocked. Errors are
      // logged inside the helper.
      // ignore: unawaited_futures
      _runOneTimeCoachTipPrune();
    }
  }

  /// Send a message with multiple media attachments (images/videos).
  /// Orchestrates: batch presign -> parallel S3 upload -> send message with media_refs.
  Future<void> sendMessageWithMultiMedia(String message, List<PickedMedia> mediaList) async {
    if (_isLoading || mediaList.isEmpty) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID - user not authenticated');
      return;
    }

    final currentMessages = state.valueOrNull ?? [];

    // Determine default message based on media mix
    final hasVideo = mediaList.any((m) => m.type == ChatMediaType.video);
    final imageCount = mediaList.where((m) => m.type == ChatMediaType.image).length;
    String defaultMessage;
    if (hasVideo && mediaList.length > 1) {
      defaultMessage = 'Compare my form across these videos';
    } else if (hasVideo) {
      defaultMessage = 'Check my form';
    } else if (imageCount > 1) {
      defaultMessage = 'What do you see in these photos?';
    } else {
      defaultMessage = 'What do you see?';
    }
    final actualMessage = message.isNotEmpty ? message : defaultMessage;

    // Add user message immediately (with local file for thumbnail)
    final userMessage = ChatMessage(
      role: 'user',
      content: actualMessage,
      createdAt: DateTime.now().toIso8601String(),
      mediaType: hasVideo ? 'video' : 'image',
      localFilePath: mediaList.first.file.path,
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);
    _saveToCache(userId, messagesWithUser);

    _isLoading = true;

    try {
      // Step 1: Upload progress message
      final uploadMsg = ChatMessage(
        role: 'system',
        content: 'Uploading ${mediaList.length} files...',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...messagesWithUser, uploadMsg]);

      // Step 2: Get batch presigned URLs
      final fileSpecs = mediaList.map((m) => <String, dynamic>{
        'filename': m.file.path.split('/').last,
        'content_type': m.mimeType,
        'media_type': m.type == ChatMediaType.video ? 'video' : 'image',
        'expected_size_bytes': m.sizeBytes,
      }).toList();

      final presignedItems = await _repository.getBatchPresignedUrls(files: fileSpecs);
      if (!mounted) return;

      // Step 3: Upload all to S3 in parallel with individual error handling
      final uploadResults = <bool>[];
      final uploadErrors = <int>[];
      await Future.wait(
        List.generate(mediaList.length, (i) async {
          try {
            final media = mediaList[i];
            final presigned = presignedItems[i];
            await _repository.uploadToS3(
              presignedUrl: presigned['presigned_url'] as String,
              fields: presigned['presigned_fields'] as Map<String, dynamic>?,
              file: media.file,
              contentType: media.mimeType,
            );
            uploadResults.add(true);
          } catch (e) {
            debugPrint('❌ [Chat] Upload failed for file $i: $e');
            uploadResults.add(false);
            uploadErrors.add(i);
          }
        }),
      );

      if (!mounted) return;
      final successCount = uploadResults.where((r) => r).length;
      final failCount = uploadErrors.length;

      // If all uploads failed, throw to trigger error handling
      if (successCount == 0) {
        throw Exception('All $failCount uploads failed. Please try again.');
      }

      // Show warning if some uploads failed
      if (failCount > 0) {
        final warningMsg = ChatMessage(
          role: 'system',
          content: '$successCount of ${mediaList.length} files uploaded. $failCount failed.',
          createdAt: DateTime.now().toIso8601String(),
        );
        final currentMsgs = state.valueOrNull ?? [];
        final withWarning = currentMsgs.where((m) =>
            !(m.role == 'system' && m.content.contains('Uploading'))).toList();
        state = AsyncValue.data([...withWarning, warningMsg]);
      }

      // Step 4: Show analyzing message
      final analyzingMsg = ChatMessage(
        role: 'system',
        content: hasVideo ? 'Analyzing your form...' : 'Analyzing $successCount images...',
        createdAt: DateTime.now().toIso8601String(),
      );
      final msgsAfterUpload = state.valueOrNull ?? [];
      final filteredMsgs = msgsAfterUpload.where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing') || m.content.contains('uploaded')))).toList();
      state = AsyncValue.data([...filteredMsgs, analyzingMsg]);

      // Step 5: Build media_refs only for successful uploads
      final mediaRefs = <Map<String, dynamic>>[];
      for (int i = 0; i < mediaList.length; i++) {
        if (uploadErrors.contains(i)) continue; // Skip failed uploads
        final media = mediaList[i];
        mediaRefs.add({
          's3_key': presignedItems[i]['s3_key'] as String,
          'media_type': media.type == ChatMediaType.video ? 'video' : 'image',
          'mime_type': media.mimeType,
          if (media.duration != null) 'duration_seconds': media.duration!.inSeconds.toDouble(),
        });
      }

      // Build context. Filter to user/assistant only — backend rejects any
      // other role (e.g. 'error') with a Pydantic 422.
      final history = currentMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'id': _user.id,
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'equipment': _user.equipmentList,
          'active_injuries': _user.injuriesList,
        };
      }

      final currentAISettings = _getAISettings();
      final unifiedContext = _getUnifiedContext();

      final sendResult = await _repository.sendMessage(
        message: actualMessage,
        userId: userId,
        userProfile: userProfile,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
        mediaRefs: mediaRefs,
        sessionId: _currentSessionId,
      );
      final response = sendResult.response;
      final assistantMessageId = sendResult.messageId;
      if (!mounted) return;

      if (_currentSessionId == null && sendResult.sessionId != null) {
        await _adoptSessionId(sendResult.sessionId!, userId);
      }

      await _processActionData(response.actionData);
      if (!mounted) return;

      // Remove system messages and add response
      final finalMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final assistantMessage = ChatMessage(
        id: assistantMessageId,
        role: 'assistant',
        content: _stripActionDataFromMessage(response.message),
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
        blocks: response.blocks,
        coachPersonaId: currentAISettings.coachPersonaId,
      );

      // Dedup by server-issued message_id (Realtime/loadHistory race guard).
      final alreadyPresent = assistantMessageId != null &&
          finalMsgs.any((m) => m.id == assistantMessageId);
      // Fix #10 — content/source-level dedup gate (drops auto-coach-tip
      // opt-outs and Levenshtein near-duplicates).
      final passesDedupGate =
          alreadyPresent ? false : await _shouldAppendAssistantMessage(assistantMessage);
      final newMessages = (alreadyPresent || !passesDedupGate)
          ? finalMsgs
          : [...finalMsgs, assistantMessage];
      state = AsyncValue.data(newMessages);
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending multi-media message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

      final errorMsgs = (state.valueOrNull ?? []).where((m) =>
          !(m.role == 'system' && (m.content.contains('Uploading') || m.content.contains('Analyzing')))).toList();

      final errorMessage = ChatMessage(
        role: 'error',
        content: 'Failed to analyze media: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...errorMsgs, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Clear messages and invalidate cache
  Future<void> clear() async {
    state = const AsyncValue.data([]);
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await DataCacheService.instance.invalidate(_cacheKey(userId));
    }
  }

  /// Clear the CURRENT conversation. If a real session is active it is
  /// deleted server-side (cascading its messages); then we drop into a
  /// brand-new empty chat. For a not-yet-sent draft this is just a reset.
  Future<void> clearHistory() async {
    final userId = await _apiClient.getUserId();
    final sessionId = _currentSessionId;
    // Invalidate the current session's local cache.
    if (userId != null) {
      await DataCacheService.instance.invalidate(_cacheKey(userId));
    }
    if (sessionId != null) {
      try {
        await _repository.deleteSession(sessionId);
        _refreshSessions?.call();
      } catch (e) {
        debugPrint('❌ [Chat] Failed to delete session on server: $e');
      }
    }
    // Reset to a fresh, unsent chat.
    startNewChat();
  }

  // ── Session hooks + lifecycle ─────────────────────────────────────────

  /// Wire the provider-side callbacks (publish session id + refresh list).
  void bindSessionHooks({
    required void Function(String? sessionId) onSessionChanged,
    required void Function() refreshSessions,
  }) {
    _onSessionChanged = onSessionChanged;
    _refreshSessions = refreshSessions;
  }

  /// Seed the active session id at construction WITHOUT firing the change
  /// hook (the provider value is already this id). Does not load messages —
  /// loadHistory() runs from the screen.
  void primeSessionId(String? sessionId) {
    _currentSessionId = sessionId;
  }

  /// Start a brand-new chat: clear the message list to empty and forget the
  /// active session. Does NOT hit the server — the session is created on the
  /// first /send and adopted from the response.
  void startNewChat() {
    _currentSessionId = null;
    state = const AsyncValue.data([]);
    _currentOffset = 0;
    _hasMoreMessages = true;
    _initialHistoryLoaded = false;
    _loadHistoryFuture = null;
    streamingBubble.value = null;
    _onSessionChanged?.call(null);
    debugPrint('🆕 [Chat] Started a new chat (session cleared)');
  }

  /// Switch to an existing session: set the active id and load that session's
  /// messages (cache-first, then server). Used by the history screen.
  Future<void> switchToSession(String sessionId) async {
    if (sessionId == _currentSessionId) {
      // Already on it — just ensure it's loaded.
      return loadHistory(force: true);
    }
    _currentSessionId = sessionId;
    // Reset list + pagination so the new session's history loads cleanly.
    state = const AsyncValue.data([]);
    _currentOffset = 0;
    _hasMoreMessages = true;
    _initialHistoryLoaded = false;
    _loadHistoryFuture = null;
    streamingBubble.value = null;
    _onSessionChanged?.call(sessionId);
    debugPrint('🔀 [Chat] Switched to session $sessionId');
    await loadHistory(force: true);
  }

  /// Adopt a server-created session id on the FIRST send of a new chat.
  /// Migrates the in-memory + disk cache from the 'current' (draft) key to
  /// the real session key, publishes the id, and refreshes the sessions list
  /// so the new conversation appears (with its soon-to-be-generated title).
  Future<void> _adoptSessionId(String sessionId, String userId) async {
    if (_currentSessionId == sessionId) return;
    debugPrint('🪪 [Chat] Adopting server session id=$sessionId');
    // Snapshot the draft list under the OLD ('current') key before switching.
    final draft = state.valueOrNull ?? const <ChatMessage>[];
    final oldMemKey = _memKey(userId);
    final oldCacheKey = _cacheKey(userId);
    // Switch the active id, then migrate caches under the new key.
    _currentSessionId = sessionId;
    _memCache.remove(oldMemKey);
    _memCache[_memKey(userId)] = List<ChatMessage>.unmodifiable(draft);
    try {
      await DataCacheService.instance.invalidate(oldCacheKey);
    } catch (_) {}
    await _saveToCache(userId, draft);
    _onSessionChanged?.call(sessionId);
    _refreshSessions?.call();
  }

  /// Add a system notification message (e.g., coach changed)
  void addSystemNotification(String message) {
    final notificationMessage = ChatMessage(
      role: 'system',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, notificationMessage]);
    debugPrint('📢 [Chat] System notification added: $message');
  }

  /// Plan §1c.5 — append a local assistant turn that mirrors the same
  /// Gemini insight the user already saw on the card. The [intent] is a
  /// stable key (e.g. `insight:<uuid>`) so reopening the chat later
  /// dedupes via the same marker. This turn is NOT persisted to the
  /// backend chat_history — it's a synthetic mirror of the daily insight
  /// that already lives in `coach_daily_insights`. If the user replies,
  /// the reply round-trip persists naturally and the seeded coach turn
  /// becomes anchored context for the conversation.
  void appendSeededCoachTurn({
    required String content,
    required String intent,
    String? sourceSurface,
    String? insightId,
  }) {
    final seeded = ChatMessage(
      role: 'assistant',
      content: content,
      intent: intent,
      // Source tag distinguishes a seeded turn from an organic one — the
      // existing chat-history dedup migration in this notifier already
      // uses `source` to filter auto-coach-tips, so we reuse the slot.
      source: sourceSurface == null ? 'seeded_insight' : 'seeded_$sourceSurface',
      // Carry the real insight_id + source surface so reopening the chat can
      // dedupe via the dedicated ChatMessage fields, not just the intent marker.
      insightId: insightId,
      sourceSurface: sourceSurface,
      createdAt: DateTime.now().toIso8601String(),
    );
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, seeded]);
    debugPrint('🤖 [Chat] Seeded coach turn ($intent / $sourceSurface)');
  }

  /// Plan §1c.2 — entry point for chip-driven workout-card actions
  /// dispatched from the chat screen. Wraps [_processActionData] so the
  /// chip strip in `chat_screen.dart` doesn't need a private accessor.
  ///
  /// Side effect: emits a small coach confirmation turn after the
  /// dispatch so the user sees "Done — water logged, +1 cup" instead of
  /// a silent state flip. Confirmation copy lives in the kind switch
  /// below so it stays close to the dispatch path.
  Future<void> dispatchWorkoutCardAction(
    String kind,
    Map<String, dynamic> payload,
  ) async {
    final actionData = <String, dynamic>{
      'action': kind,
      ...payload,
    };
    debugPrint('🎯 [Chat] dispatchWorkoutCardAction kind=$kind payload=$payload');
    await _handleWorkoutCardChipAction(kind, actionData);
  }

  /// Direct chip→handler routing for the 14 workout-card / morning-brief
  /// action kinds listed in plan §1c.2 + §1e. Each handler dispatches
  /// through an EXISTING surface (no new endpoints) per plan rules.
  ///
  /// Confirmation turn is appended on success; failure surfaces an error
  /// toast rather than a silent no-op per `feedback_no_silent_fallbacks`.
  Future<void> _handleWorkoutCardChipAction(
    String kind,
    Map<String, dynamic> actionData,
  ) async {
    Future<void> confirm(String text) async {
      // Append as an assistant turn so it threads into the conversation
      // naturally (vs a system banner). source tag keeps it dedupable.
      final msg = ChatMessage(
        role: 'assistant',
        content: text,
        source: 'chip_action_confirm',
        createdAt: DateTime.now().toIso8601String(),
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, msg]);
    }

    try {
      switch (kind) {
        case 'log_water_now':
          {
            final userId = await _apiClient.getUserId();
            if (userId == null) throw StateError('no user');
            // 8oz cup = ~237 ml.
            final ok = await _hydrationNotifier.logHydration(
              userId: userId,
              drinkType: 'water',
              amountMl: 237,
            );
            if (!ok) throw StateError('logHydration returned false');
            await confirm('Done, +1 cup logged (8oz water).');
            break;
          }
        case 'log_breakfast':
        case 'log_pre_workout_snack':
        case 'log_post_workout_meal':
          {
            // The chat already has a log-meal sheet flow; from here we
            // navigate to the nutrition tab with a hint so the user
            // lands in the right place. The actual sheet open is owned
            // by the nutrition screen (it accepts a `prefill_slot`
            // query param). No silent fallback — if the route is not
            // registered, GoRouter throws and we surface the error.
            final slot = kind == 'log_breakfast'
                ? 'breakfast'
                : kind == 'log_pre_workout_snack'
                    ? 'pre_workout'
                    : 'post_workout';
            _router.go('/nutrition?slot=$slot');
            await confirm('Opening meal log…');
            break;
          }
        case 'plan_tomorrow_meals':
          _router.go('/nutrition');
          await confirm('Pulling up tomorrow’s plan…');
          break;
        case 'start_wind_down':
          // Wind-down state is owned by the home workout card; routing
          // back to /home triggers its resolver to re-render in
          // windDown mode. No dedicated endpoint exists today.
          _router.go('/home');
          await confirm('Wind down it is. Lights low, screens off in 30.');
          break;
        case 'start_workout_now':
          {
            final wid = actionData['workout_id'] as String?;
            if (wid != null && wid.isNotEmpty) {
              _router.push('/workout/$wid');
            } else {
              _router.go('/workouts');
            }
            await confirm('Opening your session.');
            break;
          }
        case 'reschedule_to_tomorrow':
          {
            // Reuses the existing `_handleWorkoutModified` path which
            // already invalidates today/upcoming workout providers.
            final wid = actionData['workout_id'] as String?;
            final reschedulePayload = {
              'action': 'reschedule',
              'workout_id': wid,
              'target_date_offset_days': 1,
            };
            await _handleWorkoutModified(reschedulePayload);
            await confirm('Moved to tomorrow.');
            break;
          }
        case 'add_bonus_workout':
          _router.go('/workouts');
          await confirm('Pick a bonus session from the list.');
          break;
        case 'mark_rest_day':
          {
            final wid = actionData['workout_id'] as String?;
            final skipPayload = {
              'action': 'delete_workout',
              'workout_id': wid,
              'skip_reason': 'coach_recommended_rest',
            };
            await _handleWorkoutModified(skipPayload);
            await confirm('Today is a rest day, banked.');
            break;
          }
        case 'delay_workout_until_fast_ends':
          // No backend endpoint exists yet to reschedule against the
          // fasting timer; surface the suggestion as a coach turn so
          // the user makes the decision. Matches the rule: no silent
          // degradation, but no fake server work either.
          await confirm(
            'When your fast ends, give it 30 minutes and then start. '
            'Tap the workout card to begin then.',
          );
          break;
        case 'accept_pr_target':
          {
            final wid = actionData['workout_id'] as String?;
            if (wid != null && wid.isNotEmpty) {
              _router.push('/workout/$wid');
            } else {
              _router.go('/workouts');
            }
            await confirm('PR target locked, lift smart.');
            break;
          }
        case 'swap_to_lighter_variant':
        case 'swap_to_bodyweight_variant':
          // Real variant swap — POSTs to the backend
          // `/workouts/{id}/swap-variant` endpoint owned by
          // services/workout/variant_generator. On success we invalidate
          // the home today-workout cache so the card flips state, then
          // route to the NEW variant workout's detail screen and emit a
          // confirmation coach turn. NO silent fallback — backend errors
          // surface as the catch block's error turn.
          {
            final wid = actionData['workout_id'] as String?;
            if (wid == null || wid.isEmpty) {
              throw StateError('swap_variant: missing workout_id');
            }
            final intensity = kind == 'swap_to_bodyweight_variant'
                ? 'bodyweight'
                : 'deload';
            debugPrint(
              '🏋️ [Chat] swap-variant POST workout=$wid intensity=$intensity',
            );
            final resp =
                await _apiClient.swapWorkoutVariant(wid, intensity);
            final newId = resp['workout_id'] as String?;
            if (newId == null || newId.isEmpty) {
              throw StateError('swap_variant: backend returned no workout_id');
            }
            final newName = (resp['name'] as String?)?.trim();
            // Refresh the home card so it picks up the new variant.
            // (No standalone workoutCardContextProvider exists yet — the
            // today-workout refresh callback covers the home surface.)
            _refreshTodayWorkout();
            _router.push('/workout/$newId');
            // Coach copy kept <14 words per score_coach_line.dart pattern.
            if (kind == 'swap_to_bodyweight_variant') {
              await confirm(
                newName != null && newName.isNotEmpty
                    ? 'Swapped to bodyweight — you’re on the $newName.'
                    : 'Swapped to a bodyweight version. Opening it now.',
              );
            } else {
              await confirm(
                newName != null && newName.isNotEmpty
                    ? 'Swapped to a lighter version — you’re on the $newName.'
                    : 'Swapped to a lighter version. Opening it now.',
              );
            }
            break;
          }
        default:
          debugPrint('🎯 [Chat] Unhandled workout-card chip kind: $kind');
      }
    } catch (e) {
      debugPrint('🎯 [Chat] chip action $kind failed: $e');
      await confirm("That didn't go through. Try again from the card.");
    }
  }

  /// Send a message through the offline AI coach (local Gemma model).
  Future<void> _sendOfflineMessage(String message, String userId) async {
    _isLoading = true;

    try {
      // Build conversation history from existing messages
      final currentMessages = state.valueOrNull ?? [];
      final history = currentMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      // Build user profile context
      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'active_injuries': _user.injuriesList,
        };
      }

      // Get current workout context string
      String? workoutContext;
      final nextWorkout = _workoutsNotifier.nextWorkout;
      if (nextWorkout != null) {
        workoutContext = 'Today\'s workout: ${nextWorkout.name ?? "Workout"} '
            'with ${nextWorkout.exercises.length} exercises';
      }

      final offlineStopwatch = Stopwatch()..start();
      final response = await _offlineCoach.sendMessage(
        userMessage: message,
        conversationHistory: history,
        userProfile: userProfile,
        currentWorkoutContext: workoutContext,
      );
      offlineStopwatch.stop();

      // Attach user-perceived latency so the bubble can show "X.Xs".
      final timedResponse = response.copyWith(
        responseTimeMs: offlineStopwatch.elapsedMilliseconds,
      );

      final updatedMessages = state.valueOrNull ?? [];
      // Fix #10 — apply dedup gate even for offline replies.
      final passesDedupGate = await _shouldAppendAssistantMessage(timedResponse);
      final newMessages = passesDedupGate
          ? [...updatedMessages, timedResponse]
          : updatedMessages;
      state = AsyncValue.data(newMessages);

      // Cache offline messages too
      await _saveToCache(userId, newMessages);

      // Queue for server sync when back online
      queueOfflineMessage(message);
    } catch (e) {
      debugPrint('❌ [Chat] Offline error: $e');
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'The offline AI encountered an error: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Delete a message from state and server (#15)
  Future<void> deleteMessage(String messageId) async {
    // Remove from local state immediately
    final messages = state.valueOrNull;
    if (messages == null) return;
    final updated = messages.where((m) => m.id != messageId).toList();
    state = AsyncValue.data(updated);

    // Delete from server
    try {
      await _repository.deleteMessage(messageId);
    } catch (e) {
      debugPrint('❌ [Chat] Failed to delete message from server: $e');
    }

    // Update cache
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await _saveToCache(userId, updated);
    }
  }

  /// Load older messages for infinite scroll (#16)
  Future<void> loadOlderMessages() {
    // Session-scoped chats load the whole thread (up to 200) up-front via
    // getSessionMessages, so there is no global-history pagination to do —
    // and getChatHistory is NOT session-scoped, so paginating it here would
    // bleed other sessions' messages into the view. No-op when a session is
    // active.
    if (_currentSessionId != null) return Future.value();
    if (!_hasMoreMessages || _isLoading) return Future.value();
    // Don't paginate until the initial history fetch has settled — otherwise
    // a user who scrolls during cold-start races loadHistory with a parallel
    // offset=0 request, and the later reply clobbers the earlier state.
    if (!_initialHistoryLoaded) return Future.value();
    // Dedup concurrent scroll-driven calls onto the same in-flight future.
    if (_loadOlderFuture != null) return _loadOlderFuture!;
    _loadOlderFuture = _doLoadOlderMessages();
    return _loadOlderFuture!;
  }

  Future<void> _doLoadOlderMessages() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null || !mounted) return;

      final olderMessages = await _repository.getChatHistory(
        userId,
        limit: 50,
        offset: _currentOffset,
      );
      if (!mounted) return;

      if (olderMessages.length < 50) {
        _hasMoreMessages = false;
      }
      _currentOffset += olderMessages.length;

      // Prepend older messages to existing list, deduplicating by id
      final current = state.valueOrNull ?? [];
      final existingIds = current.map((m) => m.id).whereType<String>().toSet();
      final newOlder = olderMessages.where((m) => m.id != null && !existingIds.contains(m.id)).toList();

      if (newOlder.isNotEmpty) {
        state = AsyncValue.data([...newOlder, ...current]);
      }
    } catch (e) {
      debugPrint('❌ [Chat] Error loading older messages: $e');
    } finally {
      _loadOlderFuture = null;
    }
  }

  /// Toggle pin on a message (#27)
  Future<void> togglePin(String messageId) async {
    final messages = state.valueOrNull;
    if (messages == null) return;

    final targetMsg = messages.firstWhere((m) => m.id == messageId, orElse: () => messages.first);
    final newPinned = !targetMsg.isPinned;

    final updated = messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isPinned: newPinned);
      }
      return m;
    }).toList();
    state = AsyncValue.data(updated);

    // Save updated state to cache
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await _saveToCache(userId, updated);
    }

    // Persist to backend (fire and forget)
    try {
      await _repository.toggleMessagePin(messageId, newPinned);
    } catch (e) {
      debugPrint('❌ [Chat] Failed to persist pin to server: $e');
    }
  }

  /// Send a voice message (#28)
  Future<void> sendVoiceMessage(File audioFile, int durationMs) async {
    if (_isLoading) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately with pending status
    final userMessage = ChatMessage(
      role: 'user',
      content: 'Voice message',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.pending,
      audioDurationMs: durationMs,
    );
    final messagesWithUser = [...currentMessages, userMessage];
    state = AsyncValue.data(messagesWithUser);

    _isLoading = true;

    try {
      // Step 1: Get presigned URL for audio upload
      final filename = audioFile.path.split('/').last;
      final presignData = await _repository.getPresignedUrl(
        filename: filename,
        contentType: 'audio/m4a',
        mediaType: 'audio',
        expectedSizeBytes: await audioFile.length(),
      );

      final presignedUrl = presignData['presigned_url'] as String? ?? presignData['url'] as String;
      final s3Key = presignData['s3_key'] as String;
      final fields = presignData['presigned_fields'] as Map<String, dynamic>?;
      final publicUrl = presignData['public_url'] as String?;

      // Step 2: Upload to S3
      await _repository.uploadToS3(
        presignedUrl: presignedUrl,
        fields: fields,
        file: audioFile,
        contentType: 'audio/m4a',
      );
      if (!mounted) return;

      // Update user message with audio URL and sent status
      final updatedUserMessage = userMessage.copyWith(
        audioUrl: publicUrl ?? presignedUrl,
        status: MessageStatus.sent,
      );
      final msgsAfterUpload = (state.valueOrNull ?? []).map((m) {
        if (m.createdAt == userMessage.createdAt && m.role == 'user' && m.content == 'Voice message') {
          return updatedUserMessage;
        }
        return m;
      }).toList();
      state = AsyncValue.data(msgsAfterUpload);

      // Step 3: Send message with media_ref
      final mediaRef = {
        's3_key': s3Key,
        'media_type': 'audio',
        'mime_type': 'audio/m4a',
        'filename': filename,
        'duration_ms': durationMs,
      };

      // Filter to user/assistant — backend 422s on other roles.
      final history = currentMessages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      Map<String, dynamic>? userProfile;
      if (_user != null) {
        userProfile = {
          'id': _user.id,
          'fitness_level': _user.fitnessLevel ?? 'beginner',
          'goals': _user.goalsList,
          'equipment': _user.equipmentList,
          'active_injuries': _user.injuriesList,
        };
      }

      final currentAISettings = _getAISettings();
      final unifiedContext = _getUnifiedContext();

      final sendResult = await _repository.sendMessage(
        message: 'Voice message (${(durationMs / 1000).toStringAsFixed(1)}s)',
        userId: userId,
        userProfile: userProfile,
        conversationHistory: history,
        aiSettings: currentAISettings.toJson(),
        unifiedContext: unifiedContext,
        mediaRef: mediaRef,
        sessionId: _currentSessionId,
      );
      final response = sendResult.response;
      final assistantMessageId = sendResult.messageId;
      if (!mounted) return;

      if (_currentSessionId == null && sendResult.sessionId != null) {
        await _adoptSessionId(sendResult.sessionId!, userId);
      }

      // Mark user message as delivered
      _updateMessageStatus(updatedUserMessage, MessageStatus.delivered);

      await _processActionData(response.actionData);
      if (!mounted) return;

      final assistantMessage = ChatMessage(
        id: assistantMessageId,
        role: 'assistant',
        content: _stripActionDataFromMessage(response.message),
        intent: response.intent,
        agentType: response.agentType,
        createdAt: DateTime.now().toIso8601String(),
        actionData: response.actionData,
        blocks: response.blocks,
        coachPersonaId: currentAISettings.coachPersonaId,
      );

      final updatedMessages = state.valueOrNull ?? [];
      final alreadyPresent = assistantMessageId != null &&
          updatedMessages.any((m) => m.id == assistantMessageId);
      // Fix #10 — content/source-level dedup gate.
      final passesDedupGate =
          alreadyPresent ? false : await _shouldAppendAssistantMessage(assistantMessage);
      final newMessages = (alreadyPresent || !passesDedupGate)
          ? updatedMessages
          : [...updatedMessages, assistantMessage];
      state = AsyncValue.data(newMessages);
      await _saveToCache(userId, newMessages);
    } catch (e, stackTrace) {
      debugPrint('❌ [Chat] Error sending voice message: $e');
      debugPrint('❌ [Chat] Stack trace: $stackTrace');
      if (!mounted) return;

      _updateMessageStatus(userMessage, MessageStatus.error);

      final errorMessage = ChatMessage(
        role: 'error',
        content: 'Failed to send voice message: ${e.toString().replaceAll('Exception: ', '')}',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Sync pending offline messages when connectivity is restored (#31)
  Future<void> syncPendingMessages() async {
    if (_pendingOfflineMessages.isEmpty || !_isOnline()) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    debugPrint('🔄 [Chat] Syncing ${_pendingOfflineMessages.length} pending offline messages');

    final toSync = List<String>.from(_pendingOfflineMessages);
    for (final message in toSync) {
      try {
        await _repository.sendMessage(
          message: message,
          userId: userId,
        );
        _pendingOfflineMessages.remove(message);
        debugPrint('✅ [Chat] Synced offline message: ${message.substring(0, message.length.clamp(0, 50))}...');
      } catch (e) {
        debugPrint('❌ [Chat] Failed to sync offline message: $e');
        break; // Stop on first failure, retry later
      }
    }
  }

  /// Queue a message for offline sync (#31)
  void queueOfflineMessage(String message) {
    _pendingOfflineMessages.add(message);
    debugPrint('📝 [Chat] Queued message for offline sync (${_pendingOfflineMessages.length} pending)');
  }

  /// Clean AI message text for display:
  /// 1. Strip raw action_data JSON blobs the AI sometimes embeds in message text
  /// 2. Convert basic markdown bold (**text**) to plain text since chat has no markdown renderer
  String _stripActionDataFromMessage(String message) {
    // Strip JSON objects containing "action" key at the end of the message
    // e.g. {"action": "navigate", "destination": "nutrition"}
    final actionPattern = RegExp(
      r'\s*\{["\s]*"?action"?\s*:\s*"[^"]*"[^}]*\}\s*$',
      multiLine: true,
    );
    var cleaned = message.replaceAll(actionPattern, '').trimRight();

    // Convert markdown bold **text** to plain text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => m.group(1)!,
    );

    return cleaned.isEmpty ? message : cleaned;
  }

  /// Process action_data from AI response
  Future<void> _processActionData(Map<String, dynamic>? actionData) async {
    if (actionData == null) {
      debugPrint('🤖 [Chat] No action_data to process (null)');
      return;
    }

    final action = actionData['action'] as String?;
    debugPrint('🤖 [Chat] Processing action_data: $action');
    debugPrint('🤖 [Chat] Full action_data: $actionData');

    switch (action) {
      case 'change_setting':
        await _handleSettingChange(actionData);
        break;
      case 'navigate':
        _handleNavigation(actionData);
        break;
      case 'start_workout':
        _handleStartWorkout(actionData);
        break;
      case 'complete_workout':
        _handleCompleteWorkout(actionData);
        break;
      case 'log_hydration':
        _handleLogHydration(actionData);
        break;
      case 'log_weight':
        _handleLogWeight(actionData);
        break;
      case 'set_water_goal':
        await _handleSetWaterGoal(actionData);
        break;
      case 'generate_quick_workout':
        await _handleQuickWorkoutGenerated(actionData);
        break;
      case 'add_exercise':
      case 'remove_exercise':
      case 'replace_all_exercises':
      case 'modify_intensity':
      case 'reschedule':
      case 'delete_workout':
        await _handleWorkoutModified(actionData);
        break;
      // Issue 3: workout mutation actions. The backend tools already
      // applied create_superset / break_superset, so just refresh.
      // log_set / swap_exercise / reorder_exercises require user
      // confirmation — the ChatActionConfirmCard handles the actual
      // repo call; we only refresh once it succeeds.
      case 'create_superset':
      case 'break_superset':
        debugPrint('🏋️ [Chat] Superset op applied (${actionData['action']})');
        await _workoutsNotifier.refresh();
        break;
      case 'log_set':
      case 'swap_exercise':
      case 'reorder_exercises':
        debugPrint(
          '🏋️ [Chat] Mutation proposal awaiting confirm: ${actionData['action']}',
        );
        // No-op here — ChatActionConfirmCard drives the apply.
        break;
      // Issue 2: identify_equipment tool result. The card itself
      // (EquipmentMatchCard inside the chat bubble) carries the user
      // interaction — Swap / Add / quick-workout deeplinks fire from
      // there with full BuildContext. Here we just log and skip the
      // 'unknown action' warning so the action_data stays clean.
      case 'open_swap_or_add':
        debugPrint(
          '🏋️ [Chat] Equipment match card rendered '
          '(canonical=${actionData['canonical_name']}, '
          'matches=${(actionData['matches'] as List?)?.length ?? 0})',
        );
        break;
      case 'food_logged':
        debugPrint('🍽️ [Chat] Food logged via chat - refreshing nutrition data');
        try {
          final userId = await _apiClient.getUserId();
          if (userId != null) {
            await _nutritionNotifier.refreshAll(userId);
          }
        } catch (e) {
          debugPrint('🍽️ [Chat] Failed to refresh nutrition: $e');
        }
        break;
      case 'event_logged':
        // Generalized wellness logging via the new log_event tool.
        // Domain values: workout / food / water / sleep / weight / mood.
        // Refresh whichever providers are visible on the home screen so
        // the new entry appears in the Timeline + hero card without a
        // pull-to-refresh.
        await _handleEventLogged(actionData);
        break;
      case 'export_data':
        // AI coach offered to export the user's data — navigate to the
        // export screen with the suggested format preselected. The screen
        // reads `format` on init; anything the UI doesn't recognize falls
        // back to the default (hevy CSV). Map a couple of AI-speak aliases
        // back to our canonical format keys.
        final formatRaw = (actionData['format'] as String?)?.toLowerCase().trim();
        const aliasMap = {
          'hevy_csv': 'hevy',
          'strong_csv': 'strong',
          'fitbod_csv': 'fitbod',
          'excel': 'xlsx',
          'spreadsheet': 'xlsx',
          'pdf_report': 'pdf',
        };
        final formatKey = aliasMap[formatRaw] ?? formatRaw;
        debugPrint('📤 [Chat] export_data → navigating to export screen (format=$formatKey)');
        // Use GoRouter push with extra so the screen can preselect the format.
        _router.push(
          '/settings/export-workouts',
          extra: {'format': formatKey},
        );
        break;
      case 'open_grocery_list':
        // Emitted by the build_grocery_list nutrition agent tool. The tool
        // already persisted the list; we just hand the list_id off via the
        // pending-action holder so the next live screen with WidgetRef
        // (MainShell) can deep-link into grocery_list_screen.
        final listId = actionData['list_id'] as String?;
        if (listId != null && listId.isNotEmpty) {
          RecipeNotificationRouter.pending = RecipeNotificationActionData(
            action: 'open_grocery_list',
            groceryListId: listId,
          );
          debugPrint('🛒 [Chat] Pending open_grocery_list for list $listId');
        }
        break;
      // === CYCLE AGENT ACTIONS (Phase F) ===
      // The cycle agent's action tools already wrote to the backend
      // (`log_cycle_symptom` / `log_period_event` create the rows,
      // `set_cycle_sync_preference` updates the profile). The frontend
      // handler refreshes whichever cycle providers are mounted and, for
      // the suggestion actions, deep-links into the relevant surface.
      case 'log_cycle_symptom':
      case 'log_period_event':
      case 'set_cycle_sync_preference':
      case 'suggest_phase_workout':
      case 'suggest_phase_meals':
        await _handleCycleAction(actionData);
        break;
      // Suggested-action launcher chips are render-only — the
      // SuggestedActionsCard in the chat bubble carries the user interaction
      // (each chip launches its flow with a live BuildContext). Nothing to
      // process here; explicit no-op so the 'unknown action' warning stays
      // clean (mirrors open_swap_or_add). Note: when suggestions ride
      // alongside a primary action (e.g. generate_quick_workout), `action`
      // is that primary value and is handled by its own case above — this
      // case only fires for the standalone suggestions payload.
      case 'suggest_actions':
        debugPrint(
          '💡 [Chat] Suggested-action chips rendered '
          '(${(actionData['suggested_actions'] as List?)?.length ?? 0})',
        );
        break;
      default:
        debugPrint('🤖 [Chat] Unknown action: $action');
    }
  }

  /// Handle cycle-agent `action_data` (Phase F).
  ///
  /// All five cycle actions arrive AFTER the agent's tool already mutated
  /// the backend (symptom/period rows written, profile flag set). This
  /// handler keeps the app in sync: it invalidates the cycle providers so
  /// the Cycle screen / home card repaint with the new data, and for the
  /// two `suggest_*` actions it routes the user to the right surface.
  Future<void> _handleCycleAction(Map<String, dynamic> actionData) async {
    final action = actionData['action'] as String?;
    debugPrint('🩺 [Chat] Cycle action: $action');

    // Invalidate the cycle providers so a live Cycle screen / home card
    // repaints with the data the agent's tool just wrote. The callback
    // captures `ref` in the provider factory — the notifier itself holds
    // no Ref, mirroring `_refreshTodayWorkout`.
    _refreshCycleData();

    switch (action) {
      case 'log_cycle_symptom':
        debugPrint('🩺 [Chat] Cycle symptom logged — providers refreshed');
        break;
      case 'log_period_event':
        debugPrint('🩺 [Chat] Period event logged — providers refreshed');
        break;
      case 'set_cycle_sync_preference':
        // Profile flag (cycle_sync_workouts / cycle_sync_nutrition) was
        // updated server-side; the profile invalidation above propagates it.
        debugPrint('🩺 [Chat] Cycle sync preference updated');
        break;
      case 'suggest_phase_workout':
        // The agent recommended a phase-appropriate session — open the
        // Cycle screen so the user sees the phase guidance in context.
        _router.push('/cycle');
        break;
      case 'suggest_phase_meals':
        // Phase-aware nutrition guidance — route to the Cycle Insights tab
        // where the phase nutrition context is surfaced.
        _router.push('/cycle?tab=insights');
        break;
      default:
        debugPrint('🩺 [Chat] Unhandled cycle action: $action');
    }
  }

  /// Handle app setting changes from AI
  Future<void> _handleSettingChange(Map<String, dynamic> actionData) async {
    final settingName = actionData['setting_name'] as String?;
    final settingValue = actionData['setting_value'] as bool?;
    // Enum/string-valued settings (theme_mode, haptic_level, accent_color,
    // font_size, unit toggles) carry their choice here. Boolean toggles leave
    // it null and read `settingValue` instead.
    final settingText = (actionData['setting_value_text'] as String?)?.trim().toLowerCase();

    debugPrint('🤖 [Chat] Changing setting: $settingName = ${settingText ?? settingValue}');

    // Default for a plain on/off toggle when the model omits a value: treat as
    // "turn it on". Each notification/guilt case overrides the default where a
    // different default makes sense.
    final on = settingValue ?? true;

    switch (settingName) {
      // ── Theme / appearance ──────────────────────────────────────────────
      case 'dark_mode':
        _themeNotifier.setTheme(on ? ThemeMode.dark : ThemeMode.light);
        debugPrint('🌙 [Chat] ${on ? "Dark" : "Light"} mode via AI');
        break;
      case 'theme_mode':
        // Enum: light | dark | system. Falls back to the boolean if no text.
        final mode = switch (settingText) {
          'system' || 'auto' || 'device' => ThemeMode.system,
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => (settingValue == false ? ThemeMode.light : ThemeMode.dark),
        };
        _themeNotifier.setTheme(mode);
        debugPrint('🎨 [Chat] Theme mode → ${mode.name} via AI');
        break;
      case 'accent_color':
        final accent = _parseAccentColor(settingText);
        if (accent != null) {
          await _ref.read(accentColorProvider.notifier).setAccent(accent);
          debugPrint('🎨 [Chat] Accent color → ${accent.name} via AI');
        } else {
          _router.push('/settings/appearance');
          debugPrint('🎨 [Chat] Unknown accent "$settingText" — opened appearance');
        }
        break;
      case 'font_size':
        // Enum text → font scale. If the model gave no choice, open the page.
        final scale = switch (settingText) {
          'small' || 'smaller' => 0.9,
          'normal' || 'default' || 'medium' => 1.0,
          'large' || 'big' || 'bigger' => 1.2,
          'extra_large' || 'extra large' || 'largest' || 'huge' => 1.4,
          _ => null,
        };
        if (scale != null) {
          await _ref.read(accessibilityProvider.notifier).setFontScale(scale);
          debugPrint('🔤 [Chat] Font scale → $scale via AI');
        } else {
          _router.push('/settings/appearance');
          debugPrint('🔤 [Chat] No font size given — opened appearance');
        }
        break;
      case 'reduce_animations':
        if (_ref.read(accessibilityProvider).reduceAnimations != on) {
          await _ref.read(accessibilityProvider.notifier).toggleReduceAnimations();
        }
        debugPrint('🎬 [Chat] Reduce animations → $on via AI');
        break;
      case 'high_contrast':
        if (_ref.read(accessibilityProvider).highContrast != on) {
          await _ref.read(accessibilityProvider.notifier).toggleHighContrast();
        }
        debugPrint('🌗 [Chat] High contrast → $on via AI');
        break;
      case 'serious_mode':
        await _ref.read(seriousModeProvider.notifier).setEnabled(on);
        debugPrint('🧘 [Chat] Serious mode (celebrations off) → $on via AI');
        break;

      // ── Workout sounds ──────────────────────────────────────────────────
      case 'sounds':
      case 'sound_effects':
      case 'mute':
        final soundPrefs = _getSoundPrefs();
        await soundPrefs.setCountdownEnabled(on);
        await soundPrefs.setRestTimerEnabled(on);
        await soundPrefs.setExerciseCompletionEnabled(on);
        await soundPrefs.setWorkoutCompletionEnabled(on);
        debugPrint('🔊 [Chat] All sounds ${on ? "enabled" : "disabled"} via AI');
        break;
      case 'countdown_sounds':
        await _getSoundPrefs().setCountdownEnabled(on);
        debugPrint('🔊 [Chat] Countdown sounds → $on via AI');
        break;
      case 'rest_timer_sounds':
        await _getSoundPrefs().setRestTimerEnabled(on);
        debugPrint('🔊 [Chat] Rest timer sounds → $on via AI');
        break;
      case 'exercise_completion_sounds':
        await _getSoundPrefs().setExerciseCompletionEnabled(on);
        debugPrint('🔊 [Chat] Exercise completion chime → $on via AI');
        break;
      case 'workout_completion_sounds':
        await _getSoundPrefs().setWorkoutCompletionEnabled(on);
        debugPrint('🔊 [Chat] Workout completion chime → $on via AI');
        break;
      case 'sound_volume':
        final vol = switch (settingText) {
          'low' || 'quiet' || 'soft' => 0.3,
          'medium' || 'normal' || 'mid' => 0.6,
          'high' || 'loud' || 'max' => 1.0,
          _ => null,
        };
        if (vol != null) {
          await _getSoundPrefs().setVolume(vol);
          debugPrint('🔊 [Chat] Sound volume → $vol via AI');
        }
        break;

      // ── Voice / audio ───────────────────────────────────────────────────
      case 'voice_announcements':
      case 'tts':
      case 'text_to_speech':
        final userId = _user?.id;
        if (userId != null) {
          await _getAudioPrefs().setTtsVolume(userId, on ? 1.0 : 0.0);
          debugPrint('🗣️ [Chat] TTS → $on via AI');
        }
        break;
      case 'background_music':
        final userId = _user?.id;
        if (userId != null) {
          await _getAudioPrefs().setAllowBackgroundMusic(userId, on);
          debugPrint('🎵 [Chat] Background music → $on via AI');
        }
        break;
      case 'audio_ducking':
        final userId = _user?.id;
        if (userId != null) {
          await _getAudioPrefs().setAudioDucking(userId, on);
          debugPrint('🎚️ [Chat] Audio ducking → $on via AI');
        }
        break;
      case 'mute_during_video':
        final userId = _user?.id;
        if (userId != null) {
          await _getAudioPrefs().setMuteDuringVideo(userId, on);
          debugPrint('🔇 [Chat] Mute-during-video → $on via AI');
        }
        break;
      case 'haptics':
        await HapticService.setLevel(on ? HapticLevel.medium : HapticLevel.off);
        debugPrint('📳 [Chat] Haptics → $on via AI');
        break;
      case 'haptic_level':
        final level = switch (settingText) {
          'off' || 'none' => HapticLevel.off,
          'light' || 'low' || 'soft' => HapticLevel.light,
          'medium' || 'normal' || 'mid' => HapticLevel.medium,
          'strong' || 'high' || 'heavy' || 'max' => HapticLevel.strong,
          _ => null,
        };
        if (level != null) {
          await HapticService.setLevel(level);
          debugPrint('📳 [Chat] Haptic level → ${level.name} via AI');
        }
        break;

      // ── Notifications & reminders (direct toggles) ──────────────────────
      case 'workout_reminders':
        await _notifPrefs().setWorkoutReminders(on);
        debugPrint('🔔 [Chat] Workout reminders → $on via AI');
        break;
      case 'hydration_reminders':
        await _notifPrefs().setHydrationReminders(on);
        debugPrint('🔔 [Chat] Hydration reminders → $on via AI');
        break;
      case 'nutrition_reminders':
        await _notifPrefs().setNutritionReminders(on);
        debugPrint('🔔 [Chat] Nutrition reminders → $on via AI');
        break;
      case 'movement_reminders':
        await _notifPrefs().setMovementReminders(on);
        debugPrint('🔔 [Chat] Movement reminders → $on via AI');
        break;
      case 'habit_reminders':
        await _notifPrefs().setHabitReminders(on);
        debugPrint('🔔 [Chat] Habit reminders → $on via AI');
        break;
      case 'post_workout_meal_reminder':
        await _notifPrefs().setPostWorkoutMealReminder(on);
        debugPrint('🔔 [Chat] Post-workout meal reminder → $on via AI');
        break;
      case 'daily_briefing':
        await _notifPrefs().setDailyBriefingNudge(on);
        debugPrint('🔔 [Chat] Daily briefing → $on via AI');
        break;
      case 'streak_alerts':
        await _notifPrefs().setStreakAlerts(on);
        debugPrint('🔔 [Chat] Streak alerts → $on via AI');
        break;
      case 'achievement_alerts':
        await _notifPrefs().setMilestoneCelebration(on);
        debugPrint('🔔 [Chat] Achievement alerts → $on via AI');
        break;
      case 'weekly_summary':
        await _notifPrefs().setWeeklySummary(on);
        debugPrint('🔔 [Chat] Weekly summary → $on via AI');
        break;
      case 'ai_coach_messages':
        await _notifPrefs().setAiCoachMessages(on);
        debugPrint('🔔 [Chat] AI coach messages → $on via AI');
        break;
      case 'guilt_notifications':
        // "you missed your workout" guilt-tone nudges — default OFF when no
        // value is given, since users asking about these usually want them off.
        await _notifPrefs().setGuiltNotifications(settingValue ?? false);
        debugPrint('🔔 [Chat] Guilt notifications → ${settingValue ?? false} via AI');
        break;

      // ── Nutrition UI ────────────────────────────────────────────────────
      case 'nutrition_ai_tips':
        // toggleAiTips takes `disabled`; "tips on" => disabled=false.
        await _withNutritionPrefs((n) => n.toggleAiTips(!on));
        debugPrint('🍽️ [Chat] Nutrition AI tips → $on via AI');
        break;
      case 'nutrition_compact_view':
        await _withNutritionPrefs((n) => n.setCompactView(on));
        debugPrint('🍽️ [Chat] Nutrition compact view → $on via AI');
        break;
      case 'nutrition_quick_log':
        await _withNutritionPrefs((n) => n.setQuickLogMode(on));
        debugPrint('🍽️ [Chat] Nutrition quick-log → $on via AI');
        break;
      case 'show_macros_on_log':
        await _withNutritionPrefs((n) => n.setShowMacrosOnLog(on));
        debugPrint('🍽️ [Chat] Show macros on log → $on via AI');
        break;

      // ── Workout behavior ────────────────────────────────────────────────
      case 'week_starts_sunday':
        await _ref.read(weekStartsSundayProvider.notifier).setStartsSunday(on);
        debugPrint('📅 [Chat] Week starts Sunday → $on via AI');
        break;
      case 'fatigue_alerts':
        await _ref.read(fatigueAlertsEnabledProvider.notifier).setEnabled(on);
        debugPrint('😮‍💨 [Chat] Fatigue alerts → $on via AI');
        break;
      case 'pre_set_insight':
        await _ref.read(preSetInsightEnabledProvider.notifier).setEnabled(on);
        debugPrint('💡 [Chat] Pre-set insight → $on via AI');
        break;
      case 'voice_set_logging':
        await _ref.read(voiceSetLoggingEnabledProvider.notifier).setEnabled(on);
        debugPrint('🎙️ [Chat] Voice set logging → $on via AI');
        break;
      case 'show_synced_workouts':
        await _ref.read(showSyncedInCarouselProvider.notifier).setVisible(on);
        debugPrint('⌚ [Chat] Show synced workouts → $on via AI');
        break;
      case 'ble_heart_rate':
        await _ref.read(bleHrEnabledProvider.notifier).setEnabled(on);
        debugPrint('❤️ [Chat] BLE heart-rate → $on via AI');
        break;
      case 'ble_auto_connect':
        await _ref.read(bleHrAutoConnectProvider.notifier).setEnabled(on);
        debugPrint('❤️ [Chat] BLE auto-connect → $on via AI');
        break;
      case 'barbell_per_side':
        await _ref.read(weightIncrementsProvider.notifier).setBarbellPerSide(on);
        debugPrint('🏋️ [Chat] Barbell per-side → $on via AI');
        break;

      // ── Units (three SEPARATE settings — never collapse) ────────────────
      case 'workout_weight_unit':
        final unit = _parseWeightUnit(settingText);
        if (unit != null) {
          await _updateProfile({'workout_weight_unit': unit});
          debugPrint('⚖️ [Chat] Workout weight unit → $unit via AI');
        }
        break;
      case 'body_weight_unit':
        final unit = _parseWeightUnit(settingText);
        if (unit != null) {
          await _updateProfile({'weight_unit': unit});
          debugPrint('⚖️ [Chat] Body weight unit → $unit via AI');
        }
        break;
      case 'increment_unit':
        final unit = _parseWeightUnit(settingText);
        if (unit != null) {
          await _ref.read(weightIncrementsProvider.notifier).setUnit(unit);
          debugPrint('⚖️ [Chat] Increment unit → $unit via AI');
        }
        break;
      case 'vacation_mode':
        await _updateProfile({'in_vacation_mode': on});
        debugPrint('🏖️ [Chat] Vacation mode → $on via AI');
        break;

      // ── Settings-page fallbacks (no clean programmatic toggle) ──────────
      case 'notifications':
        _router.push('/settings/sound-notifications');
        debugPrint('🔔 [Chat] Opening notifications settings via AI');
        break;
      case 'equipment':
        _router.push('/settings/equipment');
        debugPrint('🏋️ [Chat] Opening equipment settings via AI');
        break;
      case 'workout_days':
      case 'training_split':
        _router.push('/settings/workout-settings');
        debugPrint('📅 [Chat] Opening workout settings via AI');
        break;
      case 'ai_coach_style':
      case 'coaching_style':
        _router.push('/settings/ai-coach');
        debugPrint('🤖 [Chat] Opening AI coach settings via AI');
        break;

      default:
        _router.push('/settings');
        debugPrint('🤖 [Chat] Setting "$settingName" not directly changeable, opening settings');
    }
  }

  /// Notification-preferences notifier, read fresh at action time.
  NotificationPreferencesNotifier _notifPrefs() =>
      _ref.read(notificationPreferencesProvider.notifier);

  /// Run a mutation against the nutrition-UI prefs, ensuring they're loaded
  /// first (every setter early-returns while `preferences` is null).
  Future<void> _withNutritionPrefs(
    Future<void> Function(NutritionUIPreferencesNotifier) mutate,
  ) async {
    final userId = _user?.id;
    if (userId == null) {
      _router.push('/nutrition-settings');
      return;
    }
    final notifier = _ref.read(nutritionUIPreferencesProvider.notifier);
    if (_ref.read(nutritionUIPreferencesProvider).preferences == null) {
      await notifier.load(userId);
    }
    await mutate(notifier);
  }

  /// Update fields on the user profile (auth notifier → backend PUT).
  Future<void> _updateProfile(Map<String, dynamic> updates) =>
      _ref.read(authStateProvider.notifier).updateUserProfile(updates);

  /// Normalize a free-text weight unit to the canonical 'lbs' / 'kg'.
  String? _parseWeightUnit(String? text) {
    if (text == null) return null;
    if (text.startsWith('lb') || text.contains('pound')) return 'lbs';
    if (text.startsWith('kg') || text.contains('kilo')) return 'kg';
    return null;
  }

  /// Map a free-text color name to an [AccentColor]. Returns null if unknown.
  AccentColor? _parseAccentColor(String? text) {
    if (text == null) return null;
    switch (text) {
      case 'monochrome':
      case 'mono':
      case 'black':
      case 'white':
      case 'grey':
      case 'gray':
        return AccentColor.black;
      case 'gold':
      case 'amber':
        return AccentColor.amber;
      default:
        try {
          return AccentColor.values.byName(text);
        } catch (_) {
          return null;
        }
    }
  }

  /// Handle navigation from AI
  void _handleNavigation(Map<String, dynamic> actionData) {
    final destination = actionData['destination'] as String?;
    // B3 — coach can attach query params; e.g. hydration deeplink uses
    // {fuelSection: water} so the Fuel tab opens on the water section.
    final paramsRaw = actionData['params'];
    final params = paramsRaw is Map
        ? paramsRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
        : <String, String>{};
    debugPrint('🧭 [Chat] Navigating to: $destination params=$params');

    // Map destination names to routes.
    // NOTE: `/support` and `/patterns` are intentionally NOT in this map —
    // the support flow is handled via show_options chips in the chat
    // bubble (B2), and `/patterns` was a dead route from a deprecated
    // hydration deeplink. Hydration now routes to /nutrition with
    // ?fuelSection=water.
    final routes = {
      // Main tabs
      'home': '/home',
      'nutrition': '/nutrition',
      'profile': '/profile',
      'social': '/social',
      // Workout features
      'workouts': '/workouts',
      'library': '/library',
      'schedule': '/schedule',
      'workout_builder': '/workout/build',
      // Multi-day program-template importer (Phase B) — lets the AI coach
      // route a user straight into the program builder.
      'program_builder': '/workout/program-builder',
      // Nutrition features — hydration handled below with params.
      'fasting': '/fasting',
      'food_history': '/nutrition',
      'food_library': '/nutrition',
      'recipe_suggestions': '/recipe-suggestions',
      'nutrition_settings': '/nutrition-settings',
      // Progress & analytics
      'stats': '/stats',
      'progress': '/stats',
      'milestones': '/stats/milestones',
      'exercise_history': '/stats/exercise-history',
      'muscle_analytics': '/stats/muscle-analytics',
      'progress_charts': '/progress-charts',
      'consistency': '/consistency',
      'measurements': '/measurements',
      // Chat (NB: no /support route — show_options renders contact chips)
      'chat': '/chat',
      'live_chat': '/live-chat',
      'help': '/help',
      'glossary': '/glossary',
      // Health & wellness
      'injuries': '/injuries',
      'habits': '/habits',
      'neat': '/neat',
      'metrics': '/metrics',
      'diabetes': '/diabetes',
      'plateau': '/plateau',
      'strain_prevention': '/strain-prevention',
      'hormonal_health': '/hormonal-health',
      'mood_history': '/mood-history',
      // Gamification
      'achievements': '/achievements',
      'trophy_room': '/trophy-room',
      'leaderboard': '/xp-leaderboard',
      'rewards': '/rewards',
      'summaries': '/summaries',
      // Settings
      'settings': '/settings',
      'workout_settings': '/settings/workout-settings',
      'ai_coach': '/settings/ai-coach',
      'appearance': '/settings/appearance',
      'sound_notifications': '/settings/sound-notifications',
      'equipment': '/settings/equipment',
      'offline_mode': '/settings/offline-mode',
      'privacy': '/settings/privacy-data',
      'subscription': '/settings/subscription',
    };

    // ── Hydration deeplink (B3) ───────────────────────────────────────
    // Coach hydration intent is normalized server-side to
    // destination=nutrition with params={fuelSection: water}. We also
    // accept the legacy destination="hydration" here so older clients /
    // cached responses still land on the right screen.
    if (destination == 'hydration' ||
        (destination == 'nutrition' && params['fuelSection'] == 'water')) {
      // Include tab=3 (Fuel) so the user lands on the Fuel→Water section
      // directly. Without it, NutritionScreen defaults to tab=0 (Daily) and
      // the fuelSection hint never gets applied because the Fuel tab isn't
      // mounted — earlier reports of the deep-link "opening Patterns" were
      // really opening Daily; either way, Fuel/Water is the intended target.
      _router.go('/nutrition?tab=3&fuelSection=water');
      debugPrint('🧭 [Chat] Navigated to /nutrition?tab=3&fuelSection=water');
      return;
    }

    final route = routes[destination];
    if (route != null) {
      // Append any extra params as a query string. Today only hydration
      // uses params (handled above) but this keeps the contract open.
      final qs = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final fullRoute = qs.isEmpty
          ? route
          : (route.contains('?') ? '$route&$qs' : '$route?$qs');
      // Use go for main tabs, push for nested screens
      if ({'home', 'nutrition', 'profile', 'social'}.contains(destination)) {
        _router.go(fullRoute);
      } else {
        _router.push(fullRoute);
      }
      debugPrint('🧭 [Chat] Navigated to $fullRoute');
    } else {
      // ⚠️ Unknown destination — log and surface nothing to the user.
      // Common offenders we explicitly removed: "support" (use show_options
      // chips), "patterns" (dead route from deprecated hydration flow).
      debugPrint('⚠️ [Chat] Unknown destination ignored: $destination');
    }
  }

  /// Handle start workout from AI
  void _handleStartWorkout(Map<String, dynamic> actionData) {
    final workoutId = actionData['workout_id'];
    debugPrint('🏋️ [Chat] Starting workout: $workoutId');

    // Navigate to home (where the workout is) and trigger workout start
    // The workout will auto-start when the user sees the workout screen
    _router.go('/home');

    // Navigate to workout detail with start flag
    if (workoutId != null) {
      _router.push('/workout/$workoutId?autoStart=true');
      debugPrint('🏋️ [Chat] Navigated to workout detail with auto-start');
    }
  }

  /// Handle generalized wellness event logged via the new log_event tool.
  /// Refreshes the providers a freshly-logged event would change so the home
  /// Timeline + hero card reflect it without requiring a manual pull-to-refresh.
  Future<void> _handleEventLogged(Map<String, dynamic> actionData) async {
    // Phase 6 — a single chat message can produce SEVERAL logs ("did yoga
    // and drank water"). Multi-action results arrive as an `events` list;
    // single-action results stay flat for back-compat. Normalize to a list
    // of domains and refresh each.
    final eventsList = actionData['events'] as List<dynamic>?;
    if (eventsList != null && eventsList.isNotEmpty) {
      debugPrint('📝 [Chat] Multi-event log: ${eventsList.length} events');
      for (final e in eventsList) {
        if (e is Map<String, dynamic>) {
          await _refreshForEventDomain(e['domain'] as String?);
        }
      }
      return;
    }

    final domain = actionData['domain'] as String?;
    final eventId = actionData['event_id'] as String?;
    final undoToken = actionData['undo_token'] as String?;
    debugPrint(
      '📝 [Chat] Event logged: domain=$domain, id=$eventId, '
      'undo_token=${undoToken != null ? "present" : "null"}',
    );
    await _refreshForEventDomain(domain);
  }

  /// Refresh the providers affected by one logged wellness event.
  ///
  /// NB: the Timeline section refreshes on its own — backend write hooks
  /// call invalidate_timeline_cache (api/v1/timeline_cache.py), so the next
  /// Timeline fetch returns the fresh payload.
  Future<void> _refreshForEventDomain(String? domain) async {
    // Domain-specific refreshes — match the existing pattern in this file.
    switch (domain) {
      case 'workout':
      case 'sleep':
        await _workoutsNotifier.refresh();
        _refreshTodayWorkout();
        break;
      case 'food':
        try {
          final userId = await _apiClient.getUserId();
          if (userId != null) {
            await _nutritionNotifier.refreshAll(userId);
          }
        } catch (e) {
          debugPrint('📝 [Chat] food refresh failed: $e');
        }
        break;
      case 'water':
        // Hydration provider is referenced indirectly via nutrition stats.
        try {
          final userId = await _apiClient.getUserId();
          if (userId != null) {
            await _nutritionNotifier.refreshAll(userId);
          }
        } catch (_) {}
        break;
      case 'sauna':
        // A chat-logged sauna adds calories to the home flame icon —
        // _refreshTodayWorkout() also invalidates aiBurnedCaloriesProvider.
        _refreshTodayWorkout();
        break;
      case 'weight':
      case 'mood':
      case 'measurement':
      case 'habit':
        // No global provider invalidation needed beyond the timeline refresh
        // — the home cards for these domains pull from the timeline payload,
        // and the dedicated screens (Measurements, Habits) re-fetch on view.
        break;
      default:
        debugPrint('📝 [Chat] Unknown event domain: $domain');
    }
  }

  /// Handle complete workout from AI
  Future<void> _handleCompleteWorkout(Map<String, dynamic> actionData) async {
    final workoutId = actionData['workout_id'];
    debugPrint('✅ [Chat] Completing workout: $workoutId');

    if (workoutId != null) {
      // Mark the workout as complete
      await _workoutRepository.completeWorkout(workoutId.toString());
      // Refresh workouts list AND today provider so the hero carousel +
      // week-strip checkmark flip immediately for the just-completed workout.
      await _workoutsNotifier.refresh();
      _refreshTodayWorkout();
      debugPrint('✅ [Chat] Workout marked as complete');
    }
  }

  /// Handle hydration logging from AI
  Future<void> _handleLogHydration(Map<String, dynamic> actionData) async {
    final amount = actionData['amount'] as int? ?? 1;
    debugPrint('💧 [Chat] Logging hydration: $amount glasses');

    final userId = await _apiClient.getUserId();
    if (userId == null) {
      debugPrint('❌ [Chat] No user ID for hydration logging');
      return;
    }

    // Log water - 1 glass = 250ml
    final amountMl = amount * 250;
    final success = await _hydrationNotifier.quickLog(
      userId: userId,
      drinkType: 'water',
      amountMl: amountMl,
    );

    if (success) {
      debugPrint('💧 [Chat] Successfully logged $amount glasses ($amountMl ml)');
    } else {
      debugPrint('❌ [Chat] Failed to log hydration');
    }
  }

  /// Handle weight logging from AI
  void _handleLogWeight(Map<String, dynamic> actionData) {
    final weight = (actionData['weight'] as num?)?.toDouble();
    debugPrint('⚖️ [Chat] Navigate to log weight: $weight');
    _router.push('/measurements');
  }

  /// Handle setting water goal from AI
  Future<void> _handleSetWaterGoal(Map<String, dynamic> actionData) async {
    final glasses = actionData['glasses'] as int? ?? 8;
    final goalMl = glasses * 250; // 1 glass = 250ml
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await _hydrationNotifier.updateGoal(userId, goalMl);
      debugPrint('💧 [Chat] Water goal set to $glasses glasses ($goalMl ml)');
    }
  }

  /// Handle quick workout generation from AI
  Future<void> _handleQuickWorkoutGenerated(Map<String, dynamic> actionData) async {
    final workoutId = actionData['workout_id'];
    final workoutName = actionData['workout_name'] as String?;
    final exerciseCount = actionData['exercise_count'] as int?;
    final durationMinutes = actionData['duration_minutes'];
    final workoutType = actionData['workout_type'] as String?;

    debugPrint('🏋️ [Chat] ═══════════════════════════════════════════');
    debugPrint('🏋️ [Chat] QUICK WORKOUT GENERATED SUCCESSFULLY!');
    debugPrint('🏋️ [Chat] workout_id: $workoutId');
    debugPrint('🏋️ [Chat] workout_name: $workoutName');
    debugPrint('🏋️ [Chat] exercise_count: $exerciseCount');
    debugPrint('🏋️ [Chat] duration_minutes: $durationMinutes');
    debugPrint('🏋️ [Chat] workout_type: $workoutType');
    debugPrint('🏋️ [Chat] ═══════════════════════════════════════════');

    // Refresh workouts to show the new quick workout
    debugPrint('🏋️ [Chat] Calling _workoutsNotifier.refresh()...');
    await _workoutsNotifier.refresh();
    debugPrint('🏋️ [Chat] Workouts refreshed successfully after quick workout generation');
    debugPrint('🏋️ [Chat] NOTE: The "Go to Workout" button should now appear in chat UI');
  }

  /// Handle general workout modifications from AI
  Future<void> _handleWorkoutModified(Map<String, dynamic> actionData) async {
    final action = actionData['action'] as String?;
    final workoutId = actionData['workout_id'];
    debugPrint('🏋️ [Chat] Workout modified: $action on workout $workoutId');

    // Refresh workouts to show the changes
    await _workoutsNotifier.refresh();
    debugPrint('🏋️ [Chat] Workouts refreshed after modification');
  }

  @override
  void dispose() {
    _instances.remove(this);
    streamingBubble.dispose();
    super.dispose();
  }
}
