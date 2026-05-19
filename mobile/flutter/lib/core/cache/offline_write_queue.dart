/// Part 1 of the instant-load standard — a reusable, disk-persisted offline
/// write queue.
///
/// This generalizes the per-feature queues that Phase A hand-rolled
/// (`_MealWriteQueue` in the nutrition repository, `_HydrationWriteQueue` in
/// the hydration repository). Both implement the exact same machinery:
///
///   * a versioned, user-scoped SharedPreferences slot,
///   * FIFO append with idempotency-key de-dup on enqueue,
///   * `flush` that replays in order and STOPS on the first transient failure,
///   * the idempotency key also riding on the request body so a partial flush
///     followed by an online retry can never double-apply a write.
///
/// [OfflineWriteQueue] is that machinery, exactly once, generic over the write
/// payload. A repository keeps one instance per (feature) and wires its own
/// connectivity listener + HTTP sender.
///
/// ---------------------------------------------------------------------------
/// HOW A REPOSITORY WIRES IT
/// ---------------------------------------------------------------------------
/// ```dart
/// class HydrationRepository {
///   // One queue per feature. `feature` namespaces the SharedPreferences key.
///   final _queue = OfflineWriteQueue(feature: 'hydration');
///
///   Future<void> logWater(int ml) async {
///     final body = {
///       'amount_ml': ml,
///       // Stamp a stable idempotency key — also sent to the server so it
///       // de-dupes a replayed write.
///       'idempotency_key': OfflineWriteQueue.idempotencyKey('hyd'),
///     };
///     if (await _isOffline()) {
///       // Persist for later; UI already updated optimistically.
///       await _queue.enqueue(userId: _userId, body: body);
///       return;
///     }
///     await _api.postWater(body);
///   }
///
///   // Call from a connectivity-restored listener.
///   Future<void> onBackOnline() => _queue.flush(
///         userId: _userId,
///         sender: (body) async {
///           try {
///             await _api.postWater(body);
///             return true;            // delivered — drop from queue
///           } on DioException {
///             return false;           // transient — keep + stop the flush
///           }
///         },
///       );
/// }
/// ```
///
/// For the connectivity-restored hook see [bindConnectivity].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schema version for the persisted queue envelope. A mismatch causes the
/// whole slot to be dropped (treated as empty) rather than mis-deserialized.
const int _kQueueSchemaVersion = 1;

/// SharedPreferences key prefix — `offline_wq::<feature>::<userId>`.
const String _kQueuePrefix = 'offline_wq';

/// One pending write held in the queue.
///
/// [body] is the JSON-encodable request payload exactly as the eventual
/// `sender` will receive it — it MUST already contain the idempotency key (the
/// queue also tracks [idempotencyKey] separately for de-dup, but the key has to
/// reach the server to be useful, hence it lives in the body too).
@immutable
class OfflineWriteItem {
  /// Stable client-generated key. De-dups enqueue AND lets the server de-dupe
  /// a replayed write. Generate with [OfflineWriteQueue.idempotencyKey].
  final String idempotencyKey;

  /// The request payload. Must be JSON-encodable and must embed
  /// [idempotencyKey] (commonly under an `'idempotency_key'` field).
  final Map<String, dynamic> body;

  /// Epoch millis the write was first enqueued — for ordering / debugging /
  /// optional age-based dropping by the caller.
  final int queuedAtMs;

  const OfflineWriteItem({
    required this.idempotencyKey,
    required this.body,
    required this.queuedAtMs,
  });

  Map<String, dynamic> toJson() => {
        'idempotency_key': idempotencyKey,
        'body': body,
        'queued_at_ms': queuedAtMs,
      };

  /// Rebuild from a persisted map. Throws on a malformed map — callers decode
  /// inside a try and drop the whole slot on failure.
  factory OfflineWriteItem.fromJson(Map<String, dynamic> j) => OfflineWriteItem(
        idempotencyKey: j['idempotency_key'] as String,
        body: Map<String, dynamic>.from(j['body'] as Map),
        queuedAtMs: (j['queued_at_ms'] as num).toInt(),
      );
}

/// A disk-persisted, user-scoped, FIFO, idempotency-deduped queue of writes
/// made while the device was offline (or while a write failed transiently).
///
/// One instance per feature. Thread-safe enough for the single-isolate Flutter
/// UI thread: every public method serializes its SharedPreferences access, and
/// [flush] guards against re-entrancy with [_flushing].
class OfflineWriteQueue {
  /// Namespaces this queue's storage slot, e.g. `'hydration'`, `'meal_log'`.
  final String feature;

  OfflineWriteQueue({required this.feature});

  /// Re-entrancy guard so two concurrent [flush] calls (e.g. a connectivity
  /// event racing a manual retry) don't replay the same item twice.
  bool _flushing = false;

  /// Connectivity subscription opened by [bindConnectivity], cancelled by
  /// [dispose].
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // ---- key helpers ---------------------------------------------------------

  String _key(String userId) => '$_kQueuePrefix::$feature::$userId';

  /// Generate a stable idempotency key.
  ///
  /// Format: `<prefix>_<microsecondEpoch>_<randomHex>`. Unique enough for a
  /// single device's write stream. Pass the SAME key into both the queued
  /// item and the request body so the server can de-dupe a replay.
  static String idempotencyKey([String prefix = 'wq']) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return '${prefix}_${ts}_$rand';
  }

  // ---- enqueue -------------------------------------------------------------

  /// Append a write to the on-disk queue.
  ///
  /// If [body] already carries an `'idempotency_key'` it is reused; otherwise a
  /// fresh one is generated, INJECTED into the body, and returned. De-dups: if
  /// an item with the same key is already queued this is a silent no-op (so a
  /// double-tap that fires two enqueues only persists once).
  ///
  /// Returns the idempotency key of the (possibly pre-existing) queued item.
  /// Never throws — a persistence failure is logged and the key still returns.
  Future<String> enqueue({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    // Reuse a caller-supplied key, else mint one and write it back into body.
    final existingKey = body['idempotency_key'];
    final key = (existingKey is String && existingKey.isNotEmpty)
        ? existingKey
        : idempotencyKey(feature);
    final effectiveBody = Map<String, dynamic>.from(body)
      ..['idempotency_key'] = key;

    try {
      final prefs = await SharedPreferences.getInstance();
      final items = _read(prefs, userId);
      if (items.any((i) => i.idempotencyKey == key)) {
        // Already queued — never enqueue twice.
        return key;
      }
      items.add(OfflineWriteItem(
        idempotencyKey: key,
        body: effectiveBody,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      await _persist(prefs, userId, items);
      debugPrint('📥 [OfflineWriteQueue:$feature] enqueued (depth=${items.length})');
    } catch (e) {
      debugPrint('📥 [OfflineWriteQueue:$feature] enqueue failed: $e');
    }
    return key;
  }

  // ---- flush ---------------------------------------------------------------

  /// Replay queued writes in FIFO order via [sender].
  ///
  /// [sender] returns `true` when a write was delivered (the item is dropped
  /// from the queue) and `false` for a TRANSIENT failure (offline again, 5xx,
  /// timeout) — on `false` the flush stops immediately and the remaining items
  /// stay queued in order for the next attempt.
  ///
  /// IMPORTANT: a permanent failure (4xx that will never succeed) should still
  /// return `true` from [sender] — otherwise a poison item blocks the queue
  /// forever. The sender owns that policy decision.
  ///
  /// Returns the number of items successfully flushed. Never throws.
  /// Re-entrant calls return 0 immediately (a flush is already running).
  Future<int> flush({
    required String userId,
    required Future<bool> Function(Map<String, dynamic> body) sender,
  }) async {
    if (_flushing) return 0;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      var items = _read(prefs, userId);
      if (items.isEmpty) return 0;

      var flushed = 0;
      while (items.isNotEmpty) {
        final ok = await sender(items.first.body);
        if (!ok) break; // transient — keep the rest queued, stop here
        items = items.sublist(1);
        flushed++;
        // Persist after EACH success so a crash mid-flush can't replay an
        // already-delivered write on next launch.
        await _persist(prefs, userId, items);
      }
      debugPrint(
        '📤 [OfflineWriteQueue:$feature] flushed $flushed, '
        '${items.length} remaining',
      );
      return flushed;
    } catch (e) {
      debugPrint('📤 [OfflineWriteQueue:$feature] flush failed: $e');
      return 0;
    } finally {
      _flushing = false;
    }
  }

  // ---- connectivity auto-flush --------------------------------------------

  /// Auto-flush when connectivity is restored.
  ///
  /// Subscribes to `connectivity_plus` and, on any transition into a connected
  /// state, calls [flush] for [userId] with [sender]. A short debounce absorbs
  /// the rapid multi-event bursts the OS emits while a connection settles.
  ///
  /// Call [dispose] (or just drop the [OfflineWriteQueue]) to cancel. Calling
  /// this twice cancels the previous subscription first.
  void bindConnectivity({
    required String userId,
    required Future<bool> Function(Map<String, dynamic> body) sender,
    Duration debounce = const Duration(milliseconds: 800),
  }) {
    _connSub?.cancel();
    Timer? debounceTimer;
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      debounceTimer?.cancel();
      debounceTimer = Timer(debounce, () {
        unawaited(flush(userId: userId, sender: sender));
      });
    });
  }

  /// Cancel the connectivity subscription opened by [bindConnectivity].
  Future<void> dispose() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  // ---- introspection -------------------------------------------------------

  /// Number of writes currently queued for [userId]. 0 on any error.
  Future<int> depth(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _read(prefs, userId).length;
    } catch (_) {
      return 0;
    }
  }

  /// Whether the queue for [userId] is empty. `true` on any error (fail-safe:
  /// callers gate "do we need to flush?" on this).
  Future<bool> isEmpty(String userId) async => (await depth(userId)) == 0;

  /// Drop every queued write for [userId] — use on logout / account switch.
  Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (e) {
      debugPrint('📤 [OfflineWriteQueue:$feature] clear failed: $e');
    }
  }

  // ---- internals -----------------------------------------------------------

  /// Read + decode the persisted queue. Returns an empty list on miss, schema
  /// mismatch, or any corruption — never throws.
  List<OfflineWriteItem> _read(SharedPreferences prefs, String userId) {
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return [];
      if (envelope['v'] != _kQueueSchemaVersion) return []; // drop on bump
      final items = envelope['items'];
      if (items is! List) return [];
      return items
          .whereType<Map>()
          .map((m) => OfflineWriteItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('📤 [OfflineWriteQueue:$feature] corrupt slot dropped: $e');
      return [];
    }
  }

  /// Write the queue back. An empty list removes the slot entirely.
  Future<void> _persist(
    SharedPreferences prefs,
    String userId,
    List<OfflineWriteItem> items,
  ) async {
    if (items.isEmpty) {
      await prefs.remove(_key(userId));
      return;
    }
    await prefs.setString(
      _key(userId),
      jsonEncode({
        'v': _kQueueSchemaVersion,
        'items': items.map((i) => i.toJson()).toList(),
      }),
    );
  }
}
