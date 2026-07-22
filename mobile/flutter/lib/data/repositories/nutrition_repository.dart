import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min, Random;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/nutrition.dart';
import '../models/food_patterns.dart';
import '../models/micronutrients.dart';
import '../models/nutrition_preferences.dart';
import '../models/companion_suggestion.dart';
import '../models/dish_image.dart';
import '../models/recipe.dart';
import '../models/ai_suggested_food.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import '../services/widget_service.dart';
import '../../utils/tz.dart';
import '../services/health_service.dart';
import '../providers/xp_provider.dart';
import '../providers/timeline_provider.dart';
// Stats refresh after a meal log (clears the stale-while-revalidate caches +
// invalidates the NUTRITION STATS providers). Library import cycle with
// nutrition_stats_provider is fine — only runtime symbol references, no
// top-level init dependency.
import '../providers/nutrition_stats_provider.dart';
import '../../services/post_meal_checkin_reminder.dart';
// Meal-suggestion widget — staged. Re-enable once widget feature ships.
// import '../../services/meal_suggestion_widget_service.dart';

part 'nutrition_repository_part_food_logging_progress.dart';

part 'nutrition_repository_ui.dart';

/// Reads the cached IANA timezone string from SharedPreferences.
/// Returns empty string on any error — callers skip the `tz` param if empty.
Future<String> _cachedTz() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_timezone') ?? '';
  } catch (_) {
    return '';
  }
}

/// Nutrition repository provider
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider));
});

/// Per-date nutrition state — the single source of truth for ONE date's
/// summary + logs, keyed by a `yyyy-MM-dd` (user-local) date string. Today's
/// instance is kept alive (read app-wide + prewarmed); past dates auto-dispose
/// when no widget watches them. Because the date IS the provider identity, the
/// cross-date leak the old single-slot `nutritionProvider` allowed is
/// structurally impossible.
final dailyNutritionProvider = StateNotifierProvider.autoDispose
    .family<DailyNutritionNotifier, DailyNutritionState, String>((ref, dateKey) {
  if (dateKey == todayNutritionKey()) ref.keepAlive();
  return DailyNutritionNotifier(
      ref.watch(nutritionRepositoryProvider), ref, dateKey);
});

/// User-level nutrition state (NOT date-scoped): calorie/macro targets + the
/// offline meal-write-queue depth. Singleton.
final nutritionMetaProvider =
    StateNotifierProvider<NutritionMetaNotifier, NutritionMetaState>((ref) {
  return NutritionMetaNotifier(ref.watch(nutritionRepositoryProvider), ref);
});

/// Response header naming WHY `GET /nutrition/adherence/{id}/summary` had no
/// summary to return. Server-side source of truth:
/// `backend/api/v1/nutrition/tdee_adherence.py` (`_REASON_HEADER`).
const String kAdherenceUnavailableHeader = 'X-Nutrition-Adherence-Unavailable';

/// Why the server had no adherence summary to give. Every one of these is a
/// NORMAL state, never an error — errors are 5xx and surface as
/// [AdherenceSummaryResult.failed].
enum AdherenceUnavailableReason {
  /// The user has no configured nutrition targets (fresh account, nutrition
  /// onboarding skipped, or a row whose target columns are still NULL).
  /// Targets are nullable BY DESIGN: "not configured" stays representable as
  /// not-configured here and is never scored against an invented plan.
  targetsNotConfigured,

  /// Targets ARE configured, but the user logged no food inside the requested
  /// window. Distinct from the above: the fix is "log a meal", not "set up
  /// nutrition".
  noLogsInWindow,

  /// The server said "nothing to score" without naming a reason (header
  /// absent or unrecognised — e.g. a proxy stripped it). Still authoritative:
  /// there is no summary, we just can't say which unknown it is.
  unspecified,
}

/// Outcome of one adherence-summary read.
///
/// Three states, because two of them are NOT the same thing:
///   * [available]   — a real, scored summary.
///   * [unavailable] — the server AFFIRMED there is nothing to score, and said
///                     why. Authoritative: a cached summary is now stale.
///   * [failed]      — the read did not complete (offline, 5xx, bad body). We
///                     do NOT know whether data exists; callers must keep any
///                     cached value rather than render/persist an empty state.
@immutable
class AdherenceSummaryResult {
  const AdherenceSummaryResult.available(AdherenceSummary this.summary)
      : reason = null,
        failed = false;

  const AdherenceSummaryResult.unavailable(
    AdherenceUnavailableReason this.reason,
  )   : summary = null,
        failed = false;

  const AdherenceSummaryResult.failed()
      : summary = null,
        reason = null,
        failed = true;

  /// The scored summary, or null when there is none / the read failed.
  final AdherenceSummary? summary;

  /// Why there is no summary. Null when one was returned, and null when the
  /// read failed — a failure is not a reason for emptiness.
  final AdherenceUnavailableReason? reason;

  /// The request itself did not complete. Emptiness is UNKNOWN.
  final bool failed;

  /// The server affirmatively reported "there is nothing to score". Safe to
  /// act on: clear caches, render the honest empty state.
  bool get isKnownEmpty => summary == null && !failed;
}

AdherenceUnavailableReason _adherenceReasonFromHeader(String? header) {
  switch (header) {
    // Values ship from `_REASON_NO_TARGETS` / `_REASON_NO_LOGS`.
    case 'targets-not-configured':
      return AdherenceUnavailableReason.targetsNotConfigured;
    case 'no-logs-in-window':
      return AdherenceUnavailableReason.noLogsInWindow;
    default:
      return AdherenceUnavailableReason.unspecified;
  }
}

/// Nutrition repository
class NutritionRepository {
  final ApiClient _client;

  NutritionRepository(this._client);

  // --- Client-side LRU cache for food text analysis ---
  static const int _maxCacheSize = 50;
  static final Map<String, LogFoodResponse> _analysisCache = {};
  static final List<String> _cacheOrder = []; // LRU order: most recent at end

  /// Normalize description for cache key: lowercase, trimmed, collapsed spaces
  static String _normalizeCacheKey(String description) {
    return description.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Store a result in the LRU cache, evicting oldest if full
  static void _cacheResult(String key, LogFoodResponse result) {
    // If key already exists, move it to end (most recent)
    _cacheOrder.remove(key);
    _cacheOrder.add(key);
    _analysisCache[key] = result;

    // Evict oldest entries if over capacity
    while (_cacheOrder.length > _maxCacheSize) {
      final evicted = _cacheOrder.removeAt(0);
      _analysisCache.remove(evicted);
    }
  }

  /// Look up a cached result, returning null on miss
  static LogFoodResponse? _getCached(String key) {
    final result = _analysisCache[key];
    if (result != null) {
      // Move to end (most recently used)
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
    }
    return result;
  }

  // Gap 1 — parallel client cache for the hydration split detected on an
  // analysis, keyed by the same normalized text. Stored alongside the
  // LogFoodResponse cache so a client-cache HIT on identical text still logs
  // the water on confirm. Value: {'hydration': {amount_ml, drink_type},
  // 'only': bool}.
  static final Map<String, Map<String, dynamic>> _hydrationCache = {};

  static void _cacheHydration(
    String key,
    Map<String, dynamic> hydration,
    bool hydrationOnly,
  ) {
    _hydrationCache[key] = {'hydration': hydration, 'only': hydrationOnly};
    // Bound it to the analysis cache's key set so it can't grow unbounded.
    _hydrationCache.removeWhere((k, _) => !_analysisCache.containsKey(k));
  }

  static Map<String, dynamic>? _getCachedHydration(String key) =>
      _hydrationCache[key];

  /// Generate a client-side idempotency key for a meal-log write (A11).
  ///
  /// Pass the SAME key across an offline-queued write and its later replay so
  /// the backend de-dupes — a rapid double-tap of "Log" or a reconnect replay
  /// can never create two food_log rows. Format: timestamp + random suffix.
  static String newMealIdempotencyKey() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return 'meal_${ts}_$rand';
  }

  /// Whether the device currently has connectivity. Used by [logAdjustedFood]
  /// to decide between a live write and an offline-queued one.
  static Future<bool> isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
    } catch (_) {
      return true; // assume online on error — the write itself will fail-fast
    }
  }

  /// The account the API client is currently authenticated as, or null when
  /// signed out (`clearAuth` wipes it on the Supabase signedOut event).
  ///
  /// This is the SAME id every nutrition caller passes around, so it is the
  /// only trustworthy answer to "whose queue may we replay right now?" — an
  /// in-memory `_lastLoadedUserId` outlives a sign-out and would replay one
  /// account's stranded meals under the next account's session.
  Future<String?> currentUserId() => _client.getUserId();

  // --- Deleted-while-still-saving tombstones (A12d) ---------------------
  //
  // Idempotency keys of meals the user deleted BEFORE their `/log-direct`
  // write confirmed. Skipping the server call for an `optimistic_` id is not
  // enough on its own: the POST that will CREATE that row is still in flight
  // (or still sitting in the offline queue), so seconds later the server
  // materialises the meal the user just swiped away and the next refresh
  // brings it back. The idempotency key is the only identifier shared by the
  // optimistic row, the live POST body and the queued body, so the tombstone
  // is keyed by it and consumed by [_enforcePendingDelete] the instant the
  // write confirms.
  static final Set<String> _pendingDeleteKeys = <String>{};
  static const int _maxPendingDeleteKeys = 200;

  /// Remember that [idempotencyKey]'s meal is already deleted. Insertion
  /// ordered + capped so a write that never confirms can't grow this forever.
  static void _rememberPendingDelete(String idempotencyKey) {
    _pendingDeleteKeys.add(idempotencyKey);
    while (_pendingDeleteKeys.length > _maxPendingDeleteKeys) {
      _pendingDeleteKeys.remove(_pendingDeleteKeys.first);
    }
  }

  /// Honour a delete the user made while this write was still unconfirmed.
  ///
  /// Runs on EVERY `/log-direct` completion — the live POST and the offline
  /// replay alike. The row exists server-side now, so a client-side tombstone
  /// alone would leave it on the server (and on every other device) and let it
  /// reappear on the next refresh. A delete that itself fails is persisted to
  /// [_PendingDeleteQueue] and retried on the next flush, never dropped.
  ///
  /// Returns true when this write's meal was deleted mid-flight, so the caller
  /// can skip the follow-up work (HealthKit sync) for a meal that is gone.
  Future<bool> _enforcePendingDelete(
    String userId,
    String? idempotencyKey,
    Object? responseData,
  ) async {
    if (idempotencyKey == null || idempotencyKey.isEmpty) return false;
    if (!_pendingDeleteKeys.remove(idempotencyKey)) return false;

    final rawId = responseData is Map ? responseData['food_log_id'] : null;
    final realId = rawId is String ? rawId : null;
    if (realId == null || realId.isEmpty) {
      debugPrint(
          '⚠️ [Nutrition] meal deleted mid-write confirmed without a food_log_id — cannot remove it server-side');
      return true;
    }
    debugPrint(
        '🥗 [Nutrition] log $realId was deleted while saving — removing it server-side');
    try {
      await _client.delete('/nutrition/food-logs/$realId');
    } on DioException catch (e) {
      // 404 = the row is already gone; the user's deletion has won either way.
      if (e.response?.statusCode == 404) return true;
      debugPrint(
          '❌ [Nutrition] mid-write delete of $realId failed: $e — queued for retry');
      await _PendingDeleteQueue.enqueue(userId, realId);
    } catch (e) {
      debugPrint(
          '❌ [Nutrition] mid-write delete of $realId failed: $e — queued for retry');
      await _PendingDeleteQueue.enqueue(userId, realId);
    }
    return true;
  }

  /// Replay a previously-queued meal-log request body verbatim. Used by the
  /// offline-queue flush — the body already carries its stable
  /// `idempotency_key` so the server de-dupes any write that already landed.
  Future<void> replayQueuedMealLog(Map<String, dynamic> body) async {
    final response = await _client.post('/nutrition/log-direct', data: body);
    // The user can delete a queued meal while the flush is already POSTing it
    // (the queue entry is gone, but the row now exists) — honour the delete.
    final rawKey = body['idempotency_key'];
    // Resolve the row owner for a possible retry-queued delete. The queue is
    // replayed FOR the currently-authenticated user, so the live session id is
    // the trustworthy owner; the body field is only a fallback. An empty string
    // here would reach _PendingDeleteQueue.enqueue, which early-returns on an
    // empty userId and would SILENTLY DROP a failed mid-write delete — the meal
    // the user swiped away then resurrects on the next refresh. If neither
    // source yields an id we log loudly rather than pretend the delete is safe.
    final rawUser = body['user_id'];
    var userId = rawUser is String && rawUser.isNotEmpty ? rawUser : '';
    if (userId.isEmpty) {
      userId = await currentUserId() ?? '';
    }
    if (userId.isEmpty && rawKey is String && rawKey.isNotEmpty) {
      debugPrint(
          '❌ [Nutrition] replay of $rawKey has no owner id — a mid-write delete could not be queued for retry');
    }
    await _enforcePendingDelete(
      userId,
      rawKey is String ? rawKey : null,
      response.data,
    );
  }

  /// Delete a food log.
  ///
  /// A log whose `/log-direct` write hasn't confirmed yet carries a synthetic
  /// `optimistic_<micros>_<idx>` id, not a server UUID. There is no server row
  /// to delete: the backend now guards this with `is_uuid` and answers a
  /// non-UUID id with `200 {"never_persisted": true}` (it no longer 22P02 →
  /// 500 — see `backend/api/v1/nutrition/food_logs.py::delete_food_log`). We
  /// still short-circuit here rather than call it, because simply issuing the
  /// delete would leave the still-running (or still queued) write to resurrect
  /// the meal seconds later. So the WRITE is cancelled instead: its queued body
  /// is removed, and a tombstone makes [_enforcePendingDelete] delete the row
  /// the moment the POST confirms.
  Future<void> deleteFoodLog(
    String logId, {
    /// Owner of the row — needed to drop a matching offline-queued write.
    String? userId,
    /// The pending write's `idempotency_key` (stamped on the optimistic row by
    /// `spliceLog`). Without it an unconfirmed delete cannot be matched to the
    /// write that is about to create the row, and the meal comes back.
    String? idempotencyKey,
  }) async {
    if (logId.startsWith('optimistic_')) {
      if (idempotencyKey == null || idempotencyKey.isEmpty) {
        debugPrint(
            '⚠️ [Nutrition] unconfirmed log $logId deleted without an idempotency key — its in-flight write cannot be cancelled');
        return;
      }
      _rememberPendingDelete(idempotencyKey);
      if (userId != null && userId.isNotEmpty) {
        await _MealWriteQueue.removeByIdempotencyKey(userId, idempotencyKey);
      }
      debugPrint(
          '🥗 [Nutrition] cancelled unconfirmed log $logId ($idempotencyKey)');
      return;
    }
    try {
      await _client.delete('/nutrition/food-logs/$logId');
    } catch (e) {
      debugPrint('Error deleting food log: $e');
      rethrow;
    }
  }

  /// Get nutrition targets
  Future<NutritionTargets> getTargets(String userId) async {
    try {
      final response = await _client.get('/nutrition/targets/$userId');
      return NutritionTargets.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting nutrition targets: $e');
      rethrow;
    }
  }

  /// Log food from text description with streaming progress updates
  ///
  /// Returns a Stream that emits progress as food is analyzed:
  /// - Step 1: Loading user profile
  /// - Step 2: Analyzing food with AI
  /// - Step 3: Calculating nutrition
  /// - Step 4: Saving to database
  Stream<FoodLoggingProgress> logFoodFromTextStreaming({
    required String userId,
    required String description,
    required String mealType,
  }) async* {
    debugPrint('🍽️ [Nutrition] Starting streaming food logging for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Starting analysis...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '/nutrition/log-text-stream',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Meal logged!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming food logging error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to log food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  /// Log food from image with streaming progress updates
  ///
  /// Returns a Stream that emits progress as image is analyzed:
  /// - Step 1: Processing image
  /// - Step 2: AI analyzing food
  /// - Step 3: Calculating nutrition
  /// - Step 4: Saving to database
  Stream<FoodLoggingProgress> logFoodFromImageStreaming({
    required String userId,
    required String mealType,
    required File imageFile,
  }) async* {
    debugPrint('📸 [Nutrition] Starting streaming image food logging for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Preparing image...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'food_image.jpg',
        ),
      });

      final response = await streamingDio.post(
        '/nutrition/log-image-stream',
        data: formData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Meal logged!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming image food logging error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to log food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  // ============================================
  // Analyze-Only Streaming Methods (No Save)
  // ============================================

  /// Analyze food from text description with streaming progress updates
  ///
  /// DOES NOT save to database - returns analysis only for user review.
  /// Call logFoodDirect() after user confirmation to actually save.
  ///
  /// Returns a Stream that emits progress as text is analyzed:
  /// - Step 1: Loading user profile and goals
  /// - Step 2: Analyzing food with AI
  /// - Step 3: Calculating nutrition (analysis complete)
  Stream<FoodLoggingProgress> analyzeFoodFromTextStreaming({
    required String userId,
    required String description,
    required String mealType,
    String? moodBefore,
  }) async* {
    debugPrint('🔍 [Nutrition] Starting streaming food ANALYSIS for $userId');
    final startTime = DateTime.now();

    // --- Check client-side cache first ---
    final cacheKey = _normalizeCacheKey(description);
    final cached = _getCached(cacheKey);
    if (cached != null) {
      debugPrint('✅ [Nutrition] Cache HIT for: "$cacheKey"');
      final cachedHyd = _getCachedHydration(cacheKey);
      yield FoodLoggingProgress(
        step: 3,
        totalSteps: 3,
        message: 'Analysis complete!',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        foodLog: cached,
        isCompleted: true,
        isAnalysisOnly: true,
        hydrationDetected: cachedHyd?['hydration'] as Map<String, dynamic>?,
        isHydrationOnly: cachedHyd?['only'] == true,
      );
      return;
    }
    debugPrint('🔍 [Nutrition] Cache MISS for: "$cacheKey"');

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Starting analysis...',
        elapsedMs: 0,
        isAnalysisOnly: true,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '/nutrition/analyze-text-stream',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
          if (moodBefore != null) 'mood_before': moodBefore,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';
      // Hold the `done` payload so the late `coach_tips` event can be merged
      // into a COMPLETE foodLog (the coach-tip card needs the full meal).
      Map<String, dynamic>? doneData;

      debugPrint('🔍 [Nutrition-Text] Starting to read SSE stream...');
      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);
        debugPrint('🔍 [Nutrition-Text] SSE chunk: ${bytes.length} bytes');

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              debugPrint('🔍 [Nutrition-Text] Event: $eventType');
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  debugPrint('🔍 [Nutrition-Text] Progress: ${data['step']}/${data['total_steps']} - ${data['message']}');
                  yield FoodLoggingProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 3,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'done') {
                  debugPrint('✅ [Nutrition-Text] Analysis complete! Parsing JSON...');
                  try {
                    doneData = data;
                    final foodLog = LogFoodResponse.fromJson(data);
                    debugPrint('✅ [Nutrition-Text] Parsed: ${foodLog.totalCalories} cal, ${foodLog.foodItems.length} items');
                    // Gap 1 — water-in-text. The backend detected a beverage in
                    // the entry; carry it out-of-band so the confirm flow logs
                    // it to hydration. `is_hydration_only` => no food items.
                    final hyd = data['hydration_detected'];
                    final hydMap =
                        hyd is Map ? Map<String, dynamic>.from(hyd) : null;
                    final hydOnly = data['is_hydration_only'] == true;
                    // Gap 7 — opt-in tracker inputs to forward on confirm.
                    final trackerMicros = <String, dynamic>{
                      if (data['added_sugar_g'] != null)
                        'added_sugar_g': data['added_sugar_g'],
                      if (data['caffeine_mg'] != null)
                        'caffeine_mg': data['caffeine_mg'],
                      if (data['alcohol_g'] != null)
                        'alcohol_g': data['alcohol_g'],
                    };
                    // Cache the successful result (+ its hydration, so a
                    // client-cache hit on identical text still logs the water).
                    _cacheResult(cacheKey, foodLog);
                    if (hydMap != null) {
                      _cacheHydration(cacheKey, hydMap, hydOnly);
                    }
                    yield FoodLoggingProgress(
                      step: 3,
                      totalSteps: 3,
                      message: 'Analysis complete!',
                      elapsedMs: elapsedMs,
                      foodLog: foodLog,
                      isCompleted: true,
                      isAnalysisOnly: true,
                      hydrationDetected: hydMap,
                      isHydrationOnly: hydOnly,
                      trackerMicros:
                          trackerMicros.isEmpty ? null : trackerMicros,
                    );
                  } catch (parseError) {
                    debugPrint('❌ [Nutrition-Text] JSON parse error: $parseError');
                    debugPrint('❌ [Nutrition-Text] Raw data: $eventData');
                    yield FoodLoggingProgress(
                      step: 0,
                      totalSteps: 3,
                      message: 'Failed to parse response: $parseError',
                      elapsedMs: elapsedMs,
                      hasError: true,
                      isAnalysisOnly: true,
                    );
                  }
                } else if (eventType == 'coach_tips') {
                  // Late-arriving coaching tips — streamed AFTER `done` so the
                  // macro card already rendered fast. Merge the tip fields
                  // into the stored `done` payload and re-emit a COMPLETE
                  // foodLog so the UI can swap the shimmer for the real tip.
                  final merged = <String, dynamic>{...?doneData};
                  for (final k in const [
                    'ai_suggestion', 'encouragements', 'warnings',
                    'recommended_swap', 'health_score', 'health_score_reasons',
                    // Refines the score badge with the LLM's goal-aware score.
                    'overall_meal_score',
                    // L1 — coaching extras delivered with the late tips.
                    'next_meal_suggestion', 'over_budget_fork',
                    // Smart sauce/side suggestions (tappable chips).
                    'suggested_addons',
                    // Inflammation — fast path often omits it; the late review
                    // fills it so the "Inflammation N/10" pill can render.
                    'inflammation_score',
                  ]) {
                    if (data[k] != null) merged[k] = data[k];
                  }
                  LogFoodResponse? mergedLog;
                  if (merged.isNotEmpty) {
                    try {
                      mergedLog = LogFoodResponse.fromJson(merged);
                      _cacheResult(cacheKey, mergedLog);
                    } catch (e) {
                      debugPrint('⚠️ [Nutrition-Text] coach_tips merge parse error: $e');
                    }
                  }
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Coach tips ready',
                    elapsedMs: elapsedMs,
                    foodLog: mergedLog,
                    isCompleted: true,
                    isAnalysisOnly: true,
                    coachTips: data,
                  );
                } else if (eventType == 'error') {
                  debugPrint('❌ [Nutrition-Text] Server error: ${data['error']}');
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 3,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                    isAnalysisOnly: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition-Text] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
      debugPrint('🔍 [Nutrition-Text] SSE stream ended');
    } catch (e) {
      debugPrint('❌ [Nutrition-Text] Streaming food analysis error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Failed to analyze food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
        isAnalysisOnly: true,
      );
    }
  }

  /// Analyze food from image with streaming progress updates
  ///
  /// DOES NOT save to database - returns analysis only for user review.
  /// Call logFoodDirect() after user confirmation to actually save.
  ///
  /// Returns a Stream that emits progress as image is analyzed:
  /// - Step 1: Processing image
  /// - Step 2: AI analyzing food
  /// - Step 3: Calculating nutrition (analysis complete)
  Stream<FoodLoggingProgress> analyzeFoodFromImageStreaming({
    required String userId,
    required String mealType,
    required File imageFile,
    Uint8List? thumbBytes, // Phase-2: 768px-resized JPEG for Vision API
  }) async* {
    debugPrint('📸 [Nutrition] Starting streaming image ANALYSIS for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Preparing image...',
        elapsedMs: 0,
        isAnalysisOnly: true,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      // Phase-2 §2.0: two-artifact upload when thumbBytes provided.
      //   `image`           = 768px thumb (used by Vision API; ~120KB)
      //   `image_original`  = full-res original (archived to S3 for view-later)
      // Legacy callers (no thumbBytes) keep working — backend treats it as
      // the single-artifact path and uses `image` for both purposes.
      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        if (thumbBytes != null)
          'image': MultipartFile.fromBytes(
            thumbBytes,
            filename: 'food_thumb.jpg',
          )
        else
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'food_image.jpg',
          ),
        if (thumbBytes != null)
          'image_original': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'food_original.jpg',
          ),
      });

      final response = await streamingDio.post(
        '/nutrition/analyze-image-stream',
        data: formData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';
      // Hold the `done` payload so the late `coach_tips` event can be merged
      // into it and re-emitted as a complete foodLog (tips included).
      Map<String, dynamic>? doneData;

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 3,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'done') {
                  doneData = data;
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Analysis complete!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'coach_tips') {
                  // Late-arriving coaching tips — streamed AFTER `done` so the
                  // card already rendered fast. Merge the tip fields into the
                  // stored `done` payload and re-emit a COMPLETE foodLog; the
                  // UI re-renders the card with tips. Missing event = no tips.
                  final merged = <String, dynamic>{...?doneData};
                  for (final k in const [
                    'ai_suggestion', 'encouragements', 'warnings',
                    'recommended_swap', 'health_score', 'health_score_reasons',
                    // Refines the score badge with the LLM's goal-aware score.
                    'overall_meal_score',
                    // L1 — coaching extras delivered with the late tips.
                    'next_meal_suggestion', 'over_budget_fork',
                    // Smart sauce/side suggestions (tappable chips).
                    'suggested_addons',
                    // Inflammation — fast path often omits it; the late review
                    // fills it so the "Inflammation N/10" pill can render.
                    'inflammation_score',
                  ]) {
                    if (data[k] != null) merged[k] = data[k];
                  }
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Coach tips ready',
                    elapsedMs: elapsedMs,
                    foodLog: merged.isNotEmpty
                        ? LogFoodResponse.fromJson(merged)
                        : null,
                    isCompleted: true,
                    isAnalysisOnly: true,
                    coachTips: data,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 3,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                    isAnalysisOnly: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming image analysis error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Failed to analyze image: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
        isAnalysisOnly: true,
      );
    }
  }

  /// Parity A2 — scan a physical nutrition-facts label (analyze-only).
  ///
  /// Hits `POST /nutrition/scan-label`, which reuses the same Gemini-OCR logic
  /// as the AI-Coach chat tool `parse_nutrition_label`. Returns a
  /// [ScanImportResult] (a [LogFoodResponse] + edge-case metadata) that the
  /// food-log result sheet reviews/edits before the user commits the log.
  ///
  /// [servingsConsumed] handles C4 "label serving size ≠ amount eaten": the
  /// caller can re-call with the user's chosen serving count.
  Future<ScanImportResult> scanNutritionLabel({
    required String userId,
    required File imageFile,
    double servingsConsumed = 1.0,
    String? caption,
    /// Gap 4 — extra photos of the SAME label (e.g. wrapped around a bottle).
    /// Sent as repeated `images` parts; the backend stitches them into one set
    /// of facts. Empty for the common single-photo case.
    List<File> additionalImages = const [],
  }) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'servings_consumed': servingsConsumed,
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'nutrition_label.jpg',
      ),
      if (additionalImages.isNotEmpty)
        'images': [
          for (var i = 0; i < additionalImages.length; i++)
            await MultipartFile.fromFile(
              additionalImages[i].path,
              filename: 'nutrition_label_${i + 1}.jpg',
            ),
        ],
    });
    try {
      final response = await _client.post(
        '/nutrition/scan-label',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      return ScanImportResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _mapScanError(e, 'label');
    }
  }

  /// Parity A2 — scan a screenshot from another nutrition app (analyze-only).
  ///
  /// Hits `POST /nutrition/scan-app-screenshot`, reusing the chat tool
  /// `parse_app_screenshot` OCR logic. If the screenshot is actually a recipe
  /// or a non-nutrition page, the backend returns 422 and this throws a
  /// [ScanImportException] with [ScanImportException.routeTo] set so the
  /// caller can route to recipe/text analysis (C4).
  Future<ScanImportResult> scanAppScreenshot({
    required String userId,
    required File imageFile,
    String? caption,
  }) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'app_screenshot.jpg',
      ),
    });
    try {
      final response = await _client.post(
        '/nutrition/scan-app-screenshot',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      return ScanImportResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw _mapScanError(e, 'screenshot');
    }
  }

  /// Attach a photo to an EXISTING food log (camera-first Journal feature).
  ///
  /// Most logs are text-entered and carry no image, so the Journal calendar
  /// shows only fork icons. This uploads the picked/snapped image to
  /// `POST /nutrition/food-logs/{log_id}/image`, which persists it onto the
  /// food_logs row and returns a freshly re-signed `image_url`. The caller
  /// stamps that URL onto the in-memory log so the photo appears instantly in
  /// BOTH the Feed and the Calendar (they read the same `imageUrl`).
  ///
  /// Throws on failure — NO silent fallback (per CLAUDE.md).
  Future<String> attachPhotoToFoodLog({
    required String logId,
    required String userId,
    required File image,
  }) async {
    debugPrint('📸 [Nutrition] Attaching photo to food log $logId for $userId');
    final formData = FormData.fromMap({
      'user_id': userId,
      'image': await MultipartFile.fromFile(
        image.path,
        filename: 'food_attach.jpg',
      ),
    });
    try {
      final response = await _client.post(
        '/nutrition/food-logs/$logId/image',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final imageUrl = data['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Server did not return an image URL');
      }
      debugPrint('✅ [Nutrition] Photo attached to log $logId');
      return imageUrl;
    } on DioException catch (e) {
      debugPrint('❌ [Nutrition] Failed to attach photo to log $logId: $e');
      throw Exception(
        'Failed to attach photo. Please try again. (${e.response?.statusCode ?? 'network'})',
      );
    }
  }

  /// Convert a Dio error from a scan endpoint into a [ScanImportException].
  /// A 422 whose `detail` carries a `reason` (recipe / not_nutrition) becomes
  /// a routable exception; everything else becomes a plain user-facing message.
  ScanImportException _mapScanError(DioException e, String kind) {
    final data = e.response?.data;
    if (e.response?.statusCode == 422 && data is Map) {
      final detail = data['detail'];
      if (detail is Map && detail['reason'] != null) {
        return ScanImportException(
          (detail['message'] as String?) ?? 'Could not read this image.',
          routeTo: detail['reason'] as String?,
        );
      }
      if (detail is String) return ScanImportException(detail);
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return ScanImportException(
        'The $kind scan timed out. Check your connection and retry.',
      );
    }
    if (data is Map && data['detail'] is String) {
      return ScanImportException(data['detail'] as String);
    }
    return ScanImportException('Could not scan the $kind. Please try again.');
  }

  /// Stream progress while analyzing 1..N food photos. Backend decides the
  /// analysis mode when `analysisMode="auto"` (classifies plate vs menu vs
  /// buffet). Plate mode auto-logs one food_log row. Menu / buffet mode
  /// returns structured dish data without logging — the caller renders the
  /// MenuAnalysisSheet checklist and later calls [logSelectedMealItems] with
  /// the ticked items.
  Stream<MultiImageAnalysisProgress> analyzeFoodFromImagesStreaming({
    required String userId,
    required String mealType,
    required List<File> imageFiles,
    /// Phase-2: 768px-resized JPEG bytes per image (parallel-indexed with
    /// imageFiles). When provided, backend uses these for Vision and
    /// archives the originals to S3.
    List<Uint8List>? thumbBytesList,
    String analysisMode = 'auto',
    String? userMessage,
    String? inputType,
    /// Where a menu/bill photo was captured: 'printed' (paper menu),
    /// 'board' (overhead / drive-thru display) or 'digital' (QR menu, PDF,
    /// restaurant site, delivery-app screenshot). Selects the backend's OCR
    /// prompt preamble; ignored for plate mode.
    String sourceHint = 'printed',
    /// When true, backend analyzes but does NOT persist a food_log row for
    /// plate-classified responses; the client is responsible for opening a
    /// review UI and calling [logFoodDirect] on confirmation.
    bool confirmBeforeLog = false,
  }) async* {
    final startTime = DateTime.now();
    try {
      yield MultiImageAnalysisProgress(
        step: 0,
        totalSteps: 4,
        message: 'Preparing ${imageFiles.length} photo${imageFiles.length == 1 ? '' : 's'}...',
        elapsedMs: 0,
      );

      final baseUrl = _client.baseUrl;
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
      ));
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      // Phase-2: paired multipart when thumbBytesList provided.
      //   `images[]`           = 768px thumbs (Vision API)
      //   `images_original[]`  = full-res originals (S3 archive)
      // Backend's analyze_food_from_s3_keys path falls back to images[] for
      // both purposes when images_original[] absent (legacy path).
      final useTwoArtifact = thumbBytesList != null
          && thumbBytesList.length == imageFiles.length;
      final multipart = <MapEntry<String, MultipartFile>>[];
      for (var i = 0; i < imageFiles.length; i++) {
        if (useTwoArtifact) {
          multipart.add(MapEntry(
            'images',
            MultipartFile.fromBytes(thumbBytesList![i], filename: 'food_thumb_$i.jpg'),
          ));
          multipart.add(MapEntry(
            'images_original',
            await MultipartFile.fromFile(imageFiles[i].path, filename: 'food_original_$i.jpg'),
          ));
        } else {
          multipart.add(MapEntry(
            'images',
            await MultipartFile.fromFile(imageFiles[i].path, filename: 'food_$i.jpg'),
          ));
        }
      }
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('user_id', userId),
        MapEntry('meal_type', mealType),
        MapEntry('analysis_mode', analysisMode),
        if (userMessage != null && userMessage.isNotEmpty) MapEntry('user_message', userMessage),
        if (inputType != null && inputType.isNotEmpty) MapEntry('input_type', inputType),
        MapEntry('source_hint', sourceHint),
        if (confirmBeforeLog) const MapEntry('confirm_before_log', 'true'),
      ]);
      formData.files.addAll(multipart);

      final response = await streamingDio.post(
        '/nutrition/log-multi-image-stream',
        data: formData,
        options: Options(responseType: ResponseType.stream),
      );
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        buffer += utf8.decode(bytes);
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
                if (eventType == 'progress') {
                  yield MultiImageAnalysisProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'page') {
                  final rawItems = (data['items'] as List?) ?? const [];
                  final items = rawItems
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  final pageNum = (data['page'] as num?)?.toInt() ?? 0;
                  final totalPages = (data['total_pages'] as num?)?.toInt() ?? 0;
                  yield MultiImageAnalysisProgress(
                    step: pageNum,
                    totalSteps: totalPages,
                    message: 'Page $pageNum of $totalPages analyzed',
                    elapsedMs: elapsedMs,
                    isPageEvent: true,
                    pageNumber: pageNum,
                    totalPages: totalPages,
                    pageItems: items,
                    pageAnalysisType: data['analysis_type'] as String?,
                    pageImageUrl: data['image_url'] as String?,
                    pageStorageKey: data['storage_key'] as String?,
                  );
                } else if (eventType == 'page_error') {
                  final pageNum = (data['page'] as num?)?.toInt() ?? 0;
                  final totalPages = (data['total_pages'] as num?)?.toInt() ?? 0;
                  yield MultiImageAnalysisProgress(
                    step: pageNum,
                    totalSteps: totalPages,
                    message: 'Page $pageNum failed: ${data['error'] ?? 'unknown error'}',
                    elapsedMs: elapsedMs,
                    isPageError: true,
                    pageNumber: pageNum,
                    totalPages: totalPages,
                  );
                } else if (eventType == 'done') {
                  yield MultiImageAnalysisProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Analysis complete!',
                    elapsedMs: elapsedMs,
                    isCompleted: true,
                    result: data,
                  );
                } else if (eventType == 'error') {
                  yield MultiImageAnalysisProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition multi] SSE parse error: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }
          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      yield MultiImageAnalysisProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to analyze images: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  /// Persist the items the user ticked off from a menu / buffet analysis.
  /// One food_log row per item so daily aggregates stay correct.
  Future<Map<String, dynamic>> logSelectedMealItems({
    required String userId,
    required String mealType,
    required String analysisType, // "menu" | "buffet" | "plate"
    required List<Map<String, dynamic>> items,
    String? inputType,
    String? imageUrl,
    String? imageStorageKey,
  }) async {
    final response = await _client.post(
      '/nutrition/log-selected-items',
      data: {
        'user_id': userId,
        'meal_type': mealType,
        'analysis_type': analysisType,
        'items': items,
        if (inputType != null) 'input_type': inputType,
        if (imageUrl != null) 'image_url': imageUrl,
        if (imageStorageKey != null) 'image_storage_key': imageStorageKey,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Resolve dish thumbnails for a batch of menu items — FREE sources only.
  ///
  /// The backend chain is cache → the user's own past photos → food_database
  /// → free-licence web. It never generates, so this call always costs
  /// nothing. Names it can't resolve are simply absent from the map: the card
  /// then renders a placeholder rather than some other dish's photo.
  Future<Map<String, DishImage>> resolveDishImages({
    required List<String> names,
    bool allowWeb = true,
  }) async {
    if (names.isEmpty) return const {};
    try {
      final response = await _client.post(
        '/nutrition/dish-images/resolve',
        data: {'names': names, 'allow_web': allowWeb},
      );
      final raw = (response.data as Map<String, dynamic>?)?['images']
              as Map<String, dynamic>? ??
          const {};
      return {
        for (final entry in raw.entries)
          if (entry.value is Map)
            entry.key:
                DishImage.fromJson(Map<String, dynamic>.from(entry.value as Map)),
      };
    } catch (e) {
      debugPrint('⚠️ [Nutrition] resolveDishImages failed: $e');
      // No image is a fine outcome — the card shows its placeholder.
      return const {};
    }
  }

  /// Generate ONE dish image (costs ~$0.02 on a cache miss).
  ///
  /// Only called for the Recommended picks and dishes the user taps. Returns
  /// null when the feature is off, the daily cap is spent, or generation
  /// failed — the caller keeps its placeholder and, for the cap case, should
  /// surface [DishImageException.message].
  Future<DishImage?> generateDishImage({
    required String name,
    String? restaurantName,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/dish-images/generate',
        data: {
          'name': name,
          if (restaurantName != null && restaurantName.isNotEmpty)
            'restaurant_name': restaurantName,
        },
      );
      return DishImage.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response!.data as Map)['detail']?.toString()
          : null;
      debugPrint('⚠️ [Nutrition] generateDishImage failed: ${detail ?? e.message}');
      throw DishImageException(
        detail ?? 'Could not create an image for this dish.',
        isCapReached: e.response?.statusCode == 429,
      );
    } catch (e) {
      debugPrint('⚠️ [Nutrition] generateDishImage failed: $e');
      throw const DishImageException('Could not create an image for this dish.');
    }
  }

  /// Fetch typical-companion suggestions for a primary food.
  ///
  /// Backend merges the user's own cross-log co-occurrence history with a
  /// cached Gemini call ("often paired with this") and applies the user's
  /// rejected-pair suppressions. An **empty** list is a valid response — it
  /// tells the UI to log the primary silently without showing any sheet.
  Future<List<CompanionSuggestion>> fetchCompanions({
    required String userId,
    required String primaryFoodName,
    required String mealType,
    String locale = 'en',
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/companions',
        data: {
          'user_id': userId,
          'primary_food_name': primaryFoodName,
          'meal_type': mealType,
          'locale': locale,
        },
      );
      final raw = (response.data as Map<String, dynamic>?)?['suggestions']
              as List<dynamic>? ??
          const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CompanionSuggestion.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [Nutrition] fetchCompanions failed: $e');
      // Never fabricate sides. Let the caller fall through to silent log.
      return const [];
    }
  }

  /// Record a user-taught negative — suppress `companionName` on future
  /// companion prompts for `primaryFoodName`. Idempotent.
  Future<void> rejectCompanion({
    required String userId,
    required String primaryFoodName,
    required String companionName,
  }) async {
    try {
      await _client.post(
        '/nutrition/companions/reject',
        data: {
          'user_id': userId,
          'primary_food_name': primaryFoodName,
          'companion_name': companionName,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Nutrition] rejectCompanion failed (non-fatal): $e');
    }
  }

  /// Get all RDA (Reference Daily Allowance) values
  Future<List<NutrientRDA>> getAllRDAs() async {
    try {
      final response = await _client.get('/nutrition/rdas');
      final data = response.data as List;
      return data.map((json) => NutrientRDA.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting RDAs: $e');
      rethrow;
    }
  }

  // ============================================
  // Adaptive TDEE & Weekly Check-in Methods
  // ============================================

  /// Get the latest adaptive TDEE calculation
  Future<AdaptiveCalculation?> getAdaptiveCalculation(String userId) async {
    try {
      debugPrint('🔍 [Nutrition] Getting adaptive calculation for $userId');
      final response = await _client.get('/nutrition/adaptive/$userId');

      if (response.data == null) {
        return null;
      }

      return AdaptiveCalculation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting adaptive calculation: $e');
      return null;
    }
  }

  /// Calculate adaptive TDEE based on food intake and weight changes
  Future<AdaptiveCalculation?> calculateAdaptiveTdee(
    String userId, {
    int days = 14,
  }) async {
    try {
      debugPrint('🧮 [Nutrition] Calculating adaptive TDEE for $userId over $days days');
      final response = await _client.post(
        '/nutrition/adaptive/$userId/calculate',
        queryParameters: {'days': days},
      );

      return AdaptiveCalculation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error calculating adaptive TDEE: $e');
      return null;
    }
  }

  /// Get weekly summary data (food logs, weight, etc.)
  Future<WeeklySummaryData?> getWeeklySummary(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting weekly summary for $userId');
      final response = await _client.get('/nutrition/weekly-summary/$userId');

      return WeeklySummaryData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly summary: $e');
      return null;
    }
  }

  /// Get the latest weekly nutrition recommendation
  Future<WeeklyRecommendation?> getWeeklyRecommendation(String userId) async {
    try {
      debugPrint('💡 [Nutrition] Getting weekly recommendation for $userId');
      final response = await _client.get('/nutrition/recommendations/$userId');

      if (response.data == null) {
        return null;
      }

      return WeeklyRecommendation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly recommendation: $e');
      return null;
    }
  }

  /// Generate a new weekly recommendation based on current data
  Future<WeeklyRecommendation?> generateWeeklyRecommendation(String userId) async {
    try {
      debugPrint('🎯 [Nutrition] Generating weekly recommendation for $userId');
      final response = await _client.post('/nutrition/recommendations/$userId/generate');

      return WeeklyRecommendation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error generating weekly recommendation: $e');
      return null;
    }
  }

  /// Get weekly nutrition data with daily breakdown (for charts)
  Future<WeeklyNutritionData?> getWeeklyNutrition(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting weekly nutrition data for $userId');
      final response = await _client.get('/nutrition/summary/weekly/$userId');

      if (response.data == null) {
        return null;
      }

      return WeeklyNutritionData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly nutrition data: $e');
      return null;
    }
  }

  // ============================================
  // MacroFactor-Style Enhanced Methods
  // ============================================

  /// Get detailed TDEE with confidence intervals and metabolic adaptation detection
  Future<DetailedTDEE?> getDetailedTDEE(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting detailed TDEE for $userId');
      final response = await _client.get('/nutrition/tdee/$userId/detailed');

      if (response.data == null) {
        return null;
      }

      return DetailedTDEE.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting detailed TDEE: $e');
      return null;
    }
  }

  /// Get adherence summary with sustainability score, WITH the reason when
  /// there is none.
  ///
  /// `GET /nutrition/adherence/{id}/summary` answers `200` + a JSON `null` body
  /// when there is nothing to score, naming the reason in the
  /// [kAdherenceUnavailableHeader] header
  /// (`backend/api/v1/nutrition/tdee_adherence.py::_adherence_unavailable`).
  /// Real failures are 5xx, so a null body NEVER means "something broke" — and
  /// a 5xx never means "no data". Folding both into a bare `null` return (the
  /// old behaviour) threw that distinction away, which is why a stale adherence
  /// card could never be cleared: the caller had no way to tell "the server
  /// says you have nothing" from "the request failed, keep what you have".
  Future<AdherenceSummaryResult> getAdherenceSummaryResult(
    String userId, {
    int weeks = 4,
  }) async {
    try {
      debugPrint('📈 [Nutrition] Getting adherence summary for $userId (${weeks}w)');
      final response = await _client.get(
        '/nutrition/adherence/$userId/summary',
        queryParameters: {'weeks': weeks},
      );

      final data = response.data;
      if (data == null) {
        final reason = _adherenceReasonFromHeader(
          response.headers.value(kAdherenceUnavailableHeader),
        );
        debugPrint('ℹ️ [Nutrition] No adherence summary to show (${reason.name})');
        return AdherenceSummaryResult.unavailable(reason);
      }

      if (data is! Map) {
        // A 200 whose body is neither JSON `null` nor an object breaks the
        // contract. Treat it as a FAILURE, not as "no data": clearing a cached
        // summary on a body we could not understand would be a guess.
        debugPrint(
          '❌ [Nutrition] Adherence summary body was ${data.runtimeType}, '
          'expected a JSON object or null',
        );
        return const AdherenceSummaryResult.failed();
      }

      return AdherenceSummaryResult.available(
        AdherenceSummary.fromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // A 404 is only "you have no configured targets" when the SERVER said
        // so SEMANTICALLY. The current backend never 404s this route — the
        // no-targets case is a 200 with a JSON `null` body plus the
        // X-Nutrition-Adherence-Unavailable header. The ONLY 404 that means
        // targets-not-configured is the legacy pre-null contract, whose body
        // was `{"detail": "Nutrition preferences not found"}`. A generic 404
        // (gateway hiccup, route rename, transient edge error, wrong host) does
        // NOT mean the user has no data — and promoting it to `unavailable`
        // makes `isKnownEmpty` true, which the provider treats as authoritative
        // emptiness: it WIPES the memory + disk cache and repaints "not enough
        // data", destroying real cached data on a transient failure. So only a
        // positively-recognised legacy no-targets 404 clears caches; any other
        // 404 is a failed read that must PRESERVE whatever is cached.
        final headerReason =
            e.response?.headers.value(kAdherenceUnavailableHeader);
        final body = e.response?.data;
        final detail = body is Map ? body['detail'] : null;
        final isLegacyNoTargets = headerReason == 'targets-not-configured' ||
            (detail is String &&
                detail
                    .toLowerCase()
                    .contains('nutrition preferences not found'));
        if (isLegacyNoTargets) {
          debugPrint(
            'ℹ️ [Nutrition] Adherence summary 404 (legacy no-targets response) '
            'for $userId — treating as targets-not-configured',
          );
          return const AdherenceSummaryResult.unavailable(
            AdherenceUnavailableReason.targetsNotConfigured,
          );
        }
        debugPrint(
          '❌ [Nutrition] Adherence summary 404 without a no-targets signal for '
          '$userId — treating as a failed read so the cached summary is kept',
        );
        return const AdherenceSummaryResult.failed();
      }
      debugPrint(
        '❌ [Nutrition] Error getting adherence summary '
        '(${e.response?.statusCode ?? e.type.name}): $e',
      );
      return const AdherenceSummaryResult.failed();
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting adherence summary: $e');
      return const AdherenceSummaryResult.failed();
    }
  }

  /// Adherence summary, or null when there is none *or* the read failed.
  ///
  /// Convenience wrapper for callers that genuinely cannot act on the
  /// difference (the weekly check-in bundle below just hides the section
  /// either way). Anything that CACHES the result must use
  /// [getAdherenceSummaryResult] instead — see [AdherenceSummaryResult].
  Future<AdherenceSummary?> getAdherenceSummary(
    String userId, {
    int weeks = 4,
  }) async =>
      (await getAdherenceSummaryResult(userId, weeks: weeks)).summary;

  /// Get multi-option recommendations (aggressive, moderate, conservative)
  Future<RecommendationOptions?> getRecommendationOptions(String userId) async {
    try {
      debugPrint('🎯 [Nutrition] Getting recommendation options for $userId');
      final response = await _client.get('/nutrition/recommendations/$userId/options');

      if (response.data == null) {
        return null;
      }

      return RecommendationOptions.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting recommendation options: $e');
      return null;
    }
  }

  /// Get all data needed for the enhanced weekly check-in
  /// Returns combined data: DetailedTDEE, AdherenceSummary, RecommendationOptions
  Future<WeeklyCheckinData?> getWeeklyCheckinData(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Loading weekly check-in data for $userId');

      // Fetch all data in parallel — each guarded so one failure doesn't nuke all
      final results = await Future.wait([
        getDetailedTDEE(userId).catchError((_) => null),
        getAdherenceSummary(userId).catchError((_) => null),
        getRecommendationOptions(userId).catchError((_) => null),
        getWeeklySummary(userId).catchError((_) => null),
      ]);

      final detailedTdee = results[0] as DetailedTDEE?;
      final adherence = results[1] as AdherenceSummary?;
      final options = results[2] as RecommendationOptions?;
      final summary = results[3] as WeeklySummaryData?;

      return WeeklyCheckinData(
        detailedTdee: detailedTdee,
        adherenceSummary: adherence,
        recommendationOptions: options,
        weeklySummary: summary,
      );
    } catch (e) {
      debugPrint('❌ [Nutrition] Error loading weekly check-in data: $e');
      return null;
    }
  }

  // ── Food Patterns (Nutrition > Patterns tab) ──────────────────────────────

  Future<FoodPatternsMoodResponse> getMoodPatterns(
    String userId, {
    int days = 90,
    int minLogs = 3,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/mood/$userId',
      queryParameters: {'days': days, 'min_logs': minLogs},
    );
    return FoodPatternsMoodResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<TopFoodsResponse> getTopFoods(
    String userId, {
    String metric = 'calories',
    String range = 'week',
    String? date,
    int limit = 20,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/top-foods/$userId',
      queryParameters: {
        'metric': metric,
        'range': range,
        if (date != null) 'date': date,
        'limit': limit,
      },
    );
    return TopFoodsResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<MacrosSummaryResponse> getMacrosSummary(
    String userId, {
    String range = 'week',
    String? date,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/macros-summary/$userId',
      queryParameters: {
        'range': range,
        if (date != null) 'date': date,
      },
    );
    return MacrosSummaryResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Per-day macro series over an ARBITRARY rolling window (Trends engine).
  ///
  /// Unlike [getMacrosSummary] (fixed day/week/month/90d buckets) and
  /// [getWeeklyNutrition] (hard 7-day window), this passes a `days` override
  /// so the Custom Trends chart can plot real logged per-day macros for the
  /// full selected range — 7D through 1Y and All. `days: 0` ⇒ all history.
  ///
  /// Returns null on failure so the caller surfaces an honest empty/error
  /// state rather than fabricating points.
  Future<MacrosSummaryResponse?> getMacrosSummaryRange(
    String userId, {
    required int days,
  }) async {
    try {
      final resp = await _client.get(
        '/nutrition/food-patterns/macros-summary/$userId',
        queryParameters: {'days': days},
      );
      return MacrosSummaryResponse.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } catch (e) {
      debugPrint('⚠️ [Nutrition] getMacrosSummaryRange($days) failed: $e');
      return null;
    }
  }

  /// Raw food_log rows for the Patterns timeline (Section 4).
  Future<List<Map<String, dynamic>>> getPatternsHistory(
    String userId, {
    String range = 'week',
    String? date,
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/history/$userId',
      queryParameters: {
        'range': range,
        if (date != null) 'date': date,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return items;
  }

  Future<PatternsSettings> getPatternsSettings(String userId) async {
    final resp = await _client.get('/nutrition/food-patterns/settings/$userId');
    return PatternsSettings.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  // ── Deepened Patterns (Phase 4B/4C — FE-D) ────────────────────────────────
  //
  // These return RAW decoded maps rather than typed models so the Patterns tab
  // can tolerate the backend (BE-1) shipping fields incrementally — every new
  // bucket is read defensively at the widget layer. All three fail-open
  // (return an empty envelope) so a missing/unmigrated endpoint degrades to a
  // gentle empty state instead of blanking the whole tab.

  /// Extended mood/symptom/tag correlations. Same `/mood` endpoint the typed
  /// [getMoodPatterns] uses, but returns the raw map so the new per-symptom
  /// (`bloated_count`/`bloated_pct`…) and tag-bucketed fields BE-1 is adding
  /// are accessible before the typed model is regenerated (build_runner is
  /// forbidden in this repo). Returns `{}` on failure.
  Future<Map<String, dynamic>> getMoodPatternsRaw(
    String userId, {
    int days = 90,
    int minLogs = 3,
  }) async {
    try {
      final resp = await _client.get(
        '/nutrition/food-patterns/mood/$userId',
        queryParameters: {'days': days, 'min_logs': minLogs},
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      debugPrint('⚠️ [Nutrition] getMoodPatternsRaw failed: $e');
      return const {};
    }
  }

  /// Macros summary WITH the baseline-window comparison BE-1 is adding
  /// (current-window avg vs prior-window avg + delta/trend, plus goals).
  /// `baselineWindows` requests the N-week-vs-prior framing (e.g. 4 ⇒ last 4wk
  /// vs the 4wk before that). Returns the raw map; the typed
  /// [getMacrosSummary] still serves the legacy pie/series. Returns `{}` on
  /// failure so the gentle-changes cards degrade to "not enough data yet".
  Future<Map<String, dynamic>> getMacrosSummaryWithBaseline(
    String userId, {
    String range = 'month',
    String? date,
    int baselineWeeks = 4,
  }) async {
    try {
      final resp = await _client.get(
        '/nutrition/food-patterns/macros-summary/$userId',
        queryParameters: {
          'range': range,
          if (date != null) 'date': date,
          'baseline_weeks': baselineWeeks,
          'include_baseline': true,
        },
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      debugPrint('⚠️ [Nutrition] getMacrosSummaryWithBaseline failed: $e');
      return const {};
    }
  }

  /// Gut-health / digestion correlations (Phase 4C). NEW endpoint BE-1 is
  /// building: a daily regularity series + food/tag → gut correlations
  /// ("tags before irregular days") over lagged windows. Returns `{}` if the
  /// endpoint or `digestion_logs` table isn't live yet so the section shows a
  /// gentle "start logging" empty state rather than an error.
  Future<Map<String, dynamic>> getDigestionPatterns(
    String userId, {
    int days = 90,
  }) async {
    try {
      final resp = await _client.get(
        '/nutrition/food-patterns/digestion/$userId',
        queryParameters: {'days': days},
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      debugPrint('⚠️ [Nutrition] getDigestionPatterns failed: $e');
      return const {};
    }
  }

  Future<PatternsSettings> updatePatternsSettings(
    String userId, {
    bool? postMealCheckinDisabled,
    bool? postMealReminderEnabled,
    bool? passiveInferenceEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (postMealCheckinDisabled != null) {
      body['post_meal_checkin_disabled'] = postMealCheckinDisabled;
    }
    if (postMealReminderEnabled != null) {
      body['post_meal_reminder_enabled'] = postMealReminderEnabled;
    }
    if (passiveInferenceEnabled != null) {
      body['passive_inference_enabled'] = passiveInferenceEnabled;
    }
    final resp = await _client.patch(
      '/nutrition/food-patterns/settings/$userId',
      data: body,
    );
    return PatternsSettings.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Confirm or dismiss a passive mood-inference guess on a food log.
  Future<void> patchInference(String logId, {required bool confirm}) async {
    await _client.patch(
      '/nutrition/food-logs/$logId/inference',
      data: {'action': confirm ? 'confirm' : 'dismiss'},
    );
  }

  // =========================================================================
  // Phase-2 §2.9: Dish variants (powers per-item edit Region dropdown)
  // =========================================================================

  /// Fetch regional/restaurant variants of a dish via trigram fuzzy match
  /// against food_nutrition_overrides_canonical. Returns up to 10 alternates.
  ///
  /// Used by the per-item edit sheet in [LogMealSheet] — when the user taps
  /// to edit "Chicken Biryani", show Indian / Pakistani / Hyderabadi / etc.
  /// as options.
  Future<List<DishVariant>> fetchDishVariants(String dishName) async {
    if (dishName.trim().isEmpty) return const [];
    try {
      final resp = await _client.get(
        '/nutrition/dish-variants',
        queryParameters: {'name': dishName},
      );
      final data = resp.data as Map<String, dynamic>;
      final variants = (data['variants'] as List?) ?? const [];
      return variants
          .map((v) => DishVariant.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (e) {
      debugPrint('[Nutrition] fetchDishVariants($dishName) failed: $e');
      return const [];
    }
  }

  /// Swap a logged food_item to a different regional/restaurant variant.
  /// Returns the new macros (calories, protein, carbs, fat) for the item
  /// after the swap.
  Future<DishVariantSwapResult?> swapDishVariant({
    required String foodLogId,
    required int foodItemIndex,
    required int newOverrideId,
  }) async {
    try {
      final resp = await _client.post(
        '/nutrition/dish-variants/swap',
        data: {
          'food_log_id': foodLogId,
          'food_item_index': foodItemIndex,
          'new_override_id': newOverrideId,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      return DishVariantSwapResult.fromJson(data);
    } catch (e) {
      debugPrint('[Nutrition] swapDishVariant failed: $e');
      return null;
    }
  }
}

/// Phase-2 §2.9 — one regional/restaurant variant of a dish.
class DishVariant {
  final int id;
  final String foodNameNormalized;
  final String displayName;
  final String? region;
  final String? restaurantName;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  const DishVariant({
    required this.id,
    required this.foodNameNormalized,
    required this.displayName,
    this.region,
    this.restaurantName,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
  });

  factory DishVariant.fromJson(Map<String, dynamic> j) => DishVariant(
        id: (j['id'] as num).toInt(),
        foodNameNormalized: j['food_name_normalized'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        region: j['region'] as String?,
        restaurantName: j['restaurant_name'] as String?,
        caloriesPer100g: (j['calories_per_100g'] as num?)?.toDouble(),
        proteinPer100g: (j['protein_per_100g'] as num?)?.toDouble(),
        carbsPer100g: (j['carbs_per_100g'] as num?)?.toDouble(),
        fatPer100g: (j['fat_per_100g'] as num?)?.toDouble(),
      );

  /// Display label for the dropdown — prefers restaurant > region > display.
  String get dropdownLabel {
    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return '$restaurantName · $displayName';
    }
    if (region != null && region!.isNotEmpty) {
      return '$region · $displayName';
    }
    return displayName;
  }
}

/// Phase-2 §2.9 — response from POST /dish-variants/swap.
class DishVariantSwapResult {
  final bool success;
  final int? newCalories;
  final double? newProteinG;
  final double? newCarbsG;
  final double? newFatG;

  const DishVariantSwapResult({
    required this.success,
    this.newCalories,
    this.newProteinG,
    this.newCarbsG,
    this.newFatG,
  });

  factory DishVariantSwapResult.fromJson(Map<String, dynamic> j) =>
      DishVariantSwapResult(
        success: j['success'] as bool? ?? false,
        newCalories: (j['new_calories'] as num?)?.toInt(),
        newProteinG: (j['new_protein_g'] as num?)?.toDouble(),
        newCarbsG: (j['new_carbs_g'] as num?)?.toDouble(),
        newFatG: (j['new_fat_g'] as num?)?.toDouble(),
      );
}

/// Parity A2 — result of a label / app-screenshot OCR scan.
///
/// Wraps the standard [LogFoodResponse] (so the existing result sheet renders
/// it unchanged) plus the C4 edge-case metadata from the `scan_meta` block.
class ScanImportResult {
  final LogFoodResponse response;

  /// "label" or "screenshot".
  final String kind;

  /// Label: servings printed on the package (multi-serving confirm).
  final double? servingsPerContainer;

  /// Label: servings the user told us they ate (echoed back).
  final double? servingsConsumed;

  /// Label: kcal for ONE serving — used to recompute when the user changes
  /// the serving count locally without a re-scan round trip.
  final int? perServingCalories;

  /// Fields Gemini could not read (glare / cut off).
  final List<String> unreadableFields;

  /// Unit conversions applied (e.g. "kj_converted", "per_100g_normalized").
  final List<String> unitNotes;

  /// True when the scan layout was unknown or values are shaky.
  final bool lowConfidence;

  /// Screenshot: source app name, if detected.
  final String? sourceApp;

  /// Screenshot: "nutrition_panel" (recipe/not_nutrition are 422'd earlier).
  final String? contentKind;

  /// Gap 4 — label: the core panel is still cut off (e.g. wrapped around a
  /// bottle); the client should offer to add another photo and re-scan.
  final bool needsMorePhotos;

  const ScanImportResult({
    required this.response,
    required this.kind,
    this.servingsPerContainer,
    this.servingsConsumed,
    this.perServingCalories,
    this.unreadableFields = const [],
    this.unitNotes = const [],
    this.lowConfidence = false,
    this.sourceApp,
    this.contentKind,
    this.needsMorePhotos = false,
  });

  factory ScanImportResult.fromJson(Map<String, dynamic> json) {
    final meta = (json['scan_meta'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return ScanImportResult(
      response: LogFoodResponse.fromJson(json),
      kind: meta['kind'] as String? ?? 'label',
      servingsPerContainer:
          (meta['servings_per_container'] as num?)?.toDouble(),
      servingsConsumed: (meta['servings_consumed'] as num?)?.toDouble(),
      perServingCalories: (meta['per_serving_calories'] as num?)?.toInt(),
      unreadableFields: (meta['unreadable_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unitNotes: (meta['unit_notes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lowConfidence: meta['low_confidence'] as bool? ?? false,
      sourceApp: meta['source_app'] as String?,
      contentKind: meta['content_kind'] as String?,
      needsMorePhotos: meta['needs_more_photos'] as bool? ?? false,
    );
  }
}

/// Thrown by the A2 scan endpoints. When [routeTo] is non-null the screenshot
/// was actually a recipe ("recipe") or a non-nutrition page ("not_nutrition")
/// and the caller should route the user elsewhere instead of showing an error.
class ScanImportException implements Exception {
  final String message;
  final String? routeTo;

  const ScanImportException(this.message, {this.routeTo});

  @override
  String toString() => message;
}
