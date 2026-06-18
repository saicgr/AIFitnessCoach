import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../../utils/tz.dart';

// ===========================================================================
// Model
// ===========================================================================

/// One gut-health (Bristol Stool Scale) log entry.
///
/// Mirrors the backend `digestion_logs` row this feature writes to (another
/// agent owns that endpoint). Only [bristolType] is effectively required —
/// everything else is optional so the log is genuinely one-tap. The Bristol
/// scale (1 = hard lumps … 7 = entirely liquid; 3–4 is "ideal") is a
/// clinically-recognised stool-form scale, NOT a decorative rating.
@immutable
class DigestionLog {
  final String id;
  final String userId;

  /// Bristol Stool Scale 1–7.
  final int bristolType;

  /// Optional urgency 1–3 (relaxed → urgent).
  final int? urgency;

  /// Optional duration in seconds.
  final int? durationSeconds;

  /// Optional free-vocab tags (e.g. "after coffee", "bloated").
  final List<String> tags;

  /// Optional free-text note.
  final String? notes;

  final DateTime loggedAt;

  const DigestionLog({
    required this.id,
    required this.userId,
    required this.bristolType,
    required this.loggedAt,
    this.urgency,
    this.durationSeconds,
    this.tags = const [],
    this.notes,
  });

  factory DigestionLog.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return DigestionLog(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      bristolType: (json['bristol_type'] as num?)?.toInt() ?? 4,
      urgency: (json['urgency'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      tags: rawTags is List
          ? rawTags.map((e) => e.toString()).toList()
          : const [],
      notes: json['notes'] as String?,
      loggedAt: json['logged_at'] != null
          ? (DateTime.tryParse(json['logged_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Request body for `POST /nutrition/digestion`. Optional fields are only
  /// included when present so the backend never has to distinguish "unset"
  /// from "null".
  Map<String, dynamic> toRequest({
    required String idempotencyKey,
  }) =>
      {
        'user_id': userId,
        'bristol_type': bristolType,
        if (urgency != null) 'urgency': urgency,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (tags.isNotEmpty) 'tags': tags,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        'logged_at': loggedAt.toUtc().toIso8601String(),
        'idempotency_key': idempotencyKey,
      };
}

/// Generate a client-side idempotency key for a digestion write — the same
/// pattern hydration uses, so a double-tap or a replayed offline write can't
/// double-count once the backend honours it.
String _newDigestionKey() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rand = Random().nextInt(1 << 32).toRadixString(16);
  return 'dig_${ts}_$rand';
}

// ===========================================================================
// Disk cache — today's logs, stale-while-revalidate (mirrors hydration)
// ===========================================================================

class _DigestionDiskCache {
  static const _prefix = 'digestion_today_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  static Future<List<DigestionLog>?> read(String userId, String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      if (envelope['v'] != _schemaVersion) return null;
      // Local-date guard — yesterday's log must never seed today's count.
      if (envelope['date'] != todayStr) return null;
      final items = envelope['items'];
      if (items is! List) return null;
      return items
          .whereType<Map>()
          .map((m) => DigestionLog.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('🚽 [DigestionDiskCache] read failed: $e');
      return null;
    }
  }

  static Future<void> write(
    String userId,
    String todayStr,
    List<DigestionLog> logs,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'v': _schemaVersion,
          'date': todayStr,
          'cached_at': DateTime.now().toIso8601String(),
          'items': [
            for (final l in logs)
              {
                'id': l.id,
                'user_id': l.userId,
                'bristol_type': l.bristolType,
                if (l.urgency != null) 'urgency': l.urgency,
                if (l.durationSeconds != null)
                  'duration_seconds': l.durationSeconds,
                if (l.tags.isNotEmpty) 'tags': l.tags,
                if (l.notes != null) 'notes': l.notes,
                'logged_at': l.loggedAt.toIso8601String(),
              },
          ],
        }),
      );
    } catch (e) {
      debugPrint('🚽 [DigestionDiskCache] write failed: $e');
    }
  }
}

// ===========================================================================
// Offline write queue (mirrors _HydrationWriteQueue)
// ===========================================================================

class _QueuedDigestionWrite {
  final String idempotencyKey;
  final Map<String, dynamic> body; // already includes the idempotency key
  final String userId;
  final int queuedAtMs;

  _QueuedDigestionWrite({
    required this.idempotencyKey,
    required this.body,
    required this.userId,
    required this.queuedAtMs,
  });

  Map<String, dynamic> toJson() => {
        'idempotency_key': idempotencyKey,
        'body': body,
        'user_id': userId,
        'queued_at_ms': queuedAtMs,
      };

  factory _QueuedDigestionWrite.fromJson(Map<String, dynamic> j) =>
      _QueuedDigestionWrite(
        idempotencyKey: j['idempotency_key'] as String,
        body: Map<String, dynamic>.from(j['body'] as Map),
        userId: j['user_id'] as String,
        queuedAtMs: (j['queued_at_ms'] as num).toInt(),
      );
}

class _DigestionWriteQueue {
  static const _prefix = 'digestion_write_queue_v1::';
  static const _schemaVersion = 1;

  static String _key(String userId) => '$_prefix$userId';

  static Future<void> enqueue(_QueuedDigestionWrite write) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _read(prefs, write.userId);
      if (list.any((w) => w.idempotencyKey == write.idempotencyKey)) return;
      list.add(write);
      await _persist(prefs, write.userId, list);
      debugPrint('🚽 [DigestionQueue] enqueued (depth=${list.length})');
    } catch (e) {
      debugPrint('🚽 [DigestionQueue] enqueue failed: $e');
    }
  }

  static Future<List<_QueuedDigestionWrite>> _read(
      SharedPreferences prefs, String userId) async {
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return [];
      if (envelope['v'] != _schemaVersion) return [];
      final items = envelope['items'];
      if (items is! List) return [];
      return items
          .whereType<Map>()
          .map((m) =>
              _QueuedDigestionWrite.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _persist(SharedPreferences prefs, String userId,
      List<_QueuedDigestionWrite> list) async {
    if (list.isEmpty) {
      await prefs.remove(_key(userId));
      return;
    }
    await prefs.setString(
      _key(userId),
      jsonEncode({
        'v': _schemaVersion,
        'items': list.map((w) => w.toJson()).toList(),
      }),
    );
  }

  static Future<int> flush(
    String userId,
    Future<bool> Function(_QueuedDigestionWrite) send,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var list = await _read(prefs, userId);
      if (list.isEmpty) return 0;
      var flushed = 0;
      while (list.isNotEmpty) {
        final ok = await send(list.first);
        if (!ok) break;
        list = list.sublist(1);
        flushed++;
        await _persist(prefs, userId, list);
      }
      debugPrint('🚽 [DigestionQueue] flushed $flushed, remaining ${list.length}');
      return flushed;
    } catch (e) {
      debugPrint('🚽 [DigestionQueue] flush failed: $e');
      return 0;
    }
  }

  static Future<bool> isEmpty(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (await _read(prefs, userId)).isEmpty;
    } catch (_) {
      return true;
    }
  }
}

// ===========================================================================
// Repository
// ===========================================================================

final digestionRepositoryProvider = Provider<DigestionRepository>((ref) {
  return DigestionRepository(ref.watch(apiClientProvider));
});

/// Network layer for gut-health logs. Tolerant by design: while another agent
/// is still building `POST /nutrition/digestion`, a 404 is treated as
/// "endpoint not live yet" — the caller queues the write locally rather than
/// surfacing an error (fail-open).
class DigestionRepository {
  final ApiClient _client;

  DigestionRepository(this._client);

  /// POST a digestion log. Returns the persisted [DigestionLog] on success.
  ///
  /// Throws [DigestionEndpointMissing] when the endpoint 404s so the notifier
  /// can keep the write queued (vs a real failure which rolls back). Other
  /// errors rethrow.
  Future<DigestionLog> log(Map<String, dynamic> body) async {
    try {
      final response = await _client.post('/nutrition/digestion', data: body);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DigestionLog.fromJson(data);
      }
      // Backend returned a bare ack — synthesize from the request body so the
      // optimistic entry still reconciles.
      return DigestionLog.fromJson({
        ...body,
        'id': body['idempotency_key'],
        'logged_at': body['logged_at'],
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const DigestionEndpointMissing();
      }
      debugPrint('🚽 [DigestionRepo] log failed: $e');
      rethrow;
    }
  }

  /// Fetch today's digestion logs. Fail-open: a 404 (endpoint not live) or any
  /// error returns an empty list rather than throwing — the gut card never
  /// blocks the Daily tab.
  Future<List<DigestionLog>> getTodayLogs(String userId, {String? dateStr}) async {
    try {
      final response = await _client.get(
        '/nutrition/digestion/$userId',
        queryParameters: dateStr != null ? {'date_str': dateStr} : null,
      );
      final data = response.data;
      final list = data is Map<String, dynamic> ? data['logs'] : data;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((m) => DigestionLog.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      debugPrint('🚽 [DigestionRepo] getTodayLogs failed: $e');
      return const [];
    } catch (e) {
      debugPrint('🚽 [DigestionRepo] getTodayLogs error: $e');
      return const [];
    }
  }
}

/// Sentinel thrown when the digestion endpoint isn't deployed yet (404). The
/// notifier treats it as "keep queued, no rollback" so logging still feels
/// instant and durable until the backend lands.
class DigestionEndpointMissing implements Exception {
  const DigestionEndpointMissing();
  @override
  String toString() => 'DigestionEndpointMissing';
}

// ===========================================================================
// State + notifier
// ===========================================================================

class DigestionState {
  final bool isLoading;
  final String? error;

  /// Today's logged entries (optimistic + reconciled).
  final List<DigestionLog> todayLogs;

  /// Local calendar date [todayLogs] belongs to.
  final String? date;

  const DigestionState({
    this.isLoading = false,
    this.error,
    this.todayLogs = const [],
    this.date,
  });

  int get todayCount => todayLogs.length;

  /// The most recent Bristol type logged today, if any — for the card's "Last:
  /// Type N" hint.
  int? get lastBristolType => todayLogs.isEmpty ? null : todayLogs.last.bristolType;

  DigestionState copyWith({
    bool? isLoading,
    String? error,
    List<DigestionLog>? todayLogs,
    String? date,
  }) {
    return DigestionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todayLogs: todayLogs ?? this.todayLogs,
      date: date ?? this.date,
    );
  }
}

final digestionProvider =
    StateNotifierProvider<DigestionNotifier, DigestionState>((ref) {
  return DigestionNotifier(ref.watch(digestionRepositoryProvider));
});

class DigestionNotifier extends StateNotifier<DigestionState> {
  final DigestionRepository _repository;

  String? _lastUserId;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isFlushing = false;

  DigestionNotifier(this._repository) : super(const DigestionState()) {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
      if (online) {
        Future.delayed(const Duration(milliseconds: 800), _flushQueue);
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn);
    } catch (_) {
      return true;
    }
  }

  /// Load today's logs — disk-seed first (instant, no spinner), then refresh
  /// from the network in the background. Fail-open throughout.
  Future<void> loadToday(String userId, {bool showLoading = true}) async {
    if (userId.isEmpty) return;
    _lastUserId = userId;
    final today = Tz.localDate();

    if (state.todayLogs.isEmpty || state.date != today) {
      if (showLoading) state = state.copyWith(isLoading: true, error: null);
      final cached = await _DigestionDiskCache.read(userId, today);
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          todayLogs: cached,
          date: today,
        );
      }
    }

    try {
      final logs = await _repository.getTodayLogs(userId, dateStr: today);
      // Only replace from the server when it actually returned something —
      // an empty server list while the endpoint is still missing should not
      // wipe an optimistic local entry.
      if (logs.isNotEmpty || state.todayLogs.isEmpty) {
        state = state.copyWith(isLoading: false, todayLogs: logs, date: today);
        unawaited(_DigestionDiskCache.write(userId, today, logs));
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('🚽 [Digestion] loadToday error (kept local): $e');
    }
  }

  /// Log a gut-health entry — optimistic + offline-safe.
  ///
  ///  • The card count updates IMMEDIATELY.
  ///  • Online success reconciles in place.
  ///  • A 404 (endpoint not deployed) or offline → the write is queued and the
  ///    optimistic entry stays (no rollback) so it lands when the backend is up.
  ///  • A genuine online failure rolls the optimistic entry back.
  Future<bool> logEntry({
    required String userId,
    required int bristolType,
    int? urgency,
    int? durationSeconds,
    List<String> tags = const [],
    String? notes,
  }) async {
    if (userId.isEmpty) return false;
    _lastUserId = userId;
    final today = Tz.localDate();
    final idempotencyKey = _newDigestionKey();
    final optimistic = DigestionLog(
      id: idempotencyKey,
      userId: userId,
      bristolType: bristolType,
      urgency: urgency,
      durationSeconds: durationSeconds,
      tags: tags,
      notes: notes,
      loggedAt: DateTime.now(),
    );
    final body = optimistic.toRequest(idempotencyKey: idempotencyKey);

    // Optimistic add.
    final snapshot = state.todayLogs;
    state = state.copyWith(
      error: null,
      todayLogs: [...snapshot, optimistic],
      date: today,
    );
    unawaited(_DigestionDiskCache.write(userId, today, state.todayLogs));

    // Offline → queue, keep optimistic.
    if (!await _isOnline()) {
      await _DigestionWriteQueue.enqueue(_QueuedDigestionWrite(
        idempotencyKey: idempotencyKey,
        body: body,
        userId: userId,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      debugPrint('🚽 [Digestion] offline — log queued ($idempotencyKey)');
      return true;
    }

    try {
      await _repository.log(body);
      // Reconcile from the server in the background.
      await loadToday(userId, showLoading: false);
      return true;
    } on DigestionEndpointMissing {
      // Backend not live yet — queue so it flushes once deployed. Keep the
      // optimistic entry (it's durable on disk + in the queue).
      await _DigestionWriteQueue.enqueue(_QueuedDigestionWrite(
        idempotencyKey: idempotencyKey,
        body: body,
        userId: userId,
        queuedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      debugPrint('🚽 [Digestion] endpoint missing — log queued ($idempotencyKey)');
      return true;
    } catch (e) {
      // Genuine failure — roll back.
      state = state.copyWith(
        todayLogs: snapshot,
        error: 'Could not save your log. We\'ll retry when you\'re back online.',
      );
      unawaited(_DigestionDiskCache.write(userId, today, snapshot));
      debugPrint('🚽 [Digestion] log failed, rolled back: $e');
      return false;
    }
  }

  Future<void> _flushQueue() async {
    final userId = _lastUserId;
    if (userId == null || _isFlushing) return;
    if (await _DigestionWriteQueue.isEmpty(userId)) return;
    _isFlushing = true;
    try {
      final flushed = await _DigestionWriteQueue.flush(userId, (w) async {
        try {
          await _repository.log(w.body);
          return true;
        } on DigestionEndpointMissing {
          return false; // still not live — keep queued
        } catch (e) {
          debugPrint('🚽 [Digestion] queued flush item failed: $e');
          return false;
        }
      });
      if (flushed > 0) {
        await loadToday(userId, showLoading: false);
      }
    } finally {
      _isFlushing = false;
    }
  }
}
