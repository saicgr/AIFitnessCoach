import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Riverpod provider for the OAuth sync repository.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(ref.watch(apiClientProvider));
});

/// A single row from `GET /sync/accounts` — tokens are deliberately absent.
/// Keep this shape aligned with `ConnectedAccountResponse` in
/// `backend/api/v1/oauth_sync.py` — if you add a field there, add it here too.
@immutable
class ConnectedSyncAccount {
  final String id;
  final String userId;
  final String provider;
  final String providerUserId;
  final String status;
  final List<String> scopes;
  final DateTime? lastSyncAt;
  final String? lastSyncStatus;
  final String? lastError;
  final int errorCount;
  final bool autoImport;
  final bool importStrength;
  final bool importCardio;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const ConnectedSyncAccount({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerUserId,
    required this.status,
    required this.scopes,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.lastError,
    this.errorCount = 0,
    this.autoImport = true,
    this.importStrength = true,
    this.importCardio = true,
    this.expiresAt,
    this.createdAt,
  });

  /// Parse the JSON shape returned by the backend. All datetime fields are
  /// ISO-8601 strings — we defensively tolerate nulls and bad timestamps
  /// instead of crashing the settings screen if one field is malformed.
  factory ConnectedSyncAccount.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is! String) return null;
      try {
        return DateTime.parse(raw).toUtc();
      } catch (_) {
        return null;
      }
    }

    return ConnectedSyncAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: json['provider'] as String,
      providerUserId: (json['provider_user_id'] ?? '') as String,
      status: (json['status'] ?? 'unknown') as String,
      scopes: (json['scopes'] as List?)?.cast<String>() ?? const <String>[],
      lastSyncAt: parseDate(json['last_sync_at']),
      lastSyncStatus: json['last_sync_status'] as String?,
      lastError: json['last_error'] as String?,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      autoImport: (json['auto_import'] as bool?) ?? true,
      importStrength: (json['import_strength'] as bool?) ?? true,
      importCardio: (json['import_cardio'] as bool?) ?? true,
      expiresAt: parseDate(json['expires_at']),
      createdAt: parseDate(json['created_at']),
    );
  }

  bool get isConnected => status == 'active';
  bool get needsReauth => status == 'expired';
  bool get hasError => errorCount > 0 || lastSyncStatus == 'failed';
}

/// Result of a manual-sync action.
@immutable
class ManualSyncResult {
  final String accountId;
  final int syncedCardio;
  final int syncedStrength;
  final String status;

  const ManualSyncResult({
    required this.accountId,
    required this.syncedCardio,
    required this.syncedStrength,
    required this.status,
  });

  factory ManualSyncResult.fromJson(Map<String, dynamic> json) => ManualSyncResult(
        accountId: json['account_id'] as String,
        syncedCardio: (json['synced_cardio'] as num?)?.toInt() ?? 0,
        syncedStrength: (json['synced_strength'] as num?)?.toInt() ?? 0,
        status: (json['status'] ?? 'ok') as String,
      );
}

/// Thin wrapper around the backend OAuth sync endpoints. Every method returns
/// a Dart-native type and throws a human-readable exception on failure so the
/// screens can render clean error states.
class SyncRepository {
  SyncRepository(this._client);

  final ApiClient _client;

  /// Valid provider slugs the backend accepts. Kept in sync with
  /// ``ALLOWED_PROVIDERS`` in ``backend/api/v1/oauth_sync.py``.
  static const Set<String> allowedProviders = <String>{
    'strava',
    'garmin',
    'fitbit',
    'apple_health',
    'peloton',
  };

  /// Start an OAuth flow for [provider]. Returns the authorization URL the
  /// client should open in an in-app browser.
  Future<String> beginAuth(String provider) async {
    _assertProvider(provider);
    try {
      debugPrint('🔐 [SyncRepository] begin auth → $provider');
      final response = await _client.post('/sync/oauth/$provider/begin');
      final url = (response.data as Map<String, dynamic>)['auth_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Backend returned no auth_url');
      }
      return url;
    } catch (e) {
      debugPrint('❌ [SyncRepository] beginAuth failed: $e');
      rethrow;
    }
  }

  /// Complete the OAuth flow. For OAuth2 providers (Strava/Fitbit), pass
  /// [code] + [state] captured from the deep-link callback. For credential-
  /// auth providers (Garmin/Peloton), pass [email] + [password]; the backend
  /// concatenates them server-side — neither credential is echoed anywhere
  /// except the authentication request itself.
  Future<ConnectedSyncAccount> completeAuth(
    String provider, {
    String? code,
    String? state,
    String? email,
    String? password,
  }) async {
    _assertProvider(provider);
    final body = <String, dynamic>{
      if (code != null) 'code': code,
      if (state != null) 'state': state,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
    };
    debugPrint(
      '🔐 [SyncRepository] callback → $provider (code_len=${code?.length ?? 0})',
    );
    final response = await _client.post(
      '/sync/oauth/$provider/callback',
      data: body,
    );
    final payload = response.data as Map<String, dynamic>;
    // The callback returns {account_id, initial_job_id, webhook_registered}.
    // We fetch the hydrated account afterwards so the caller gets a typed
    // ConnectedSyncAccount (the callback shape is intentionally leaner).
    final accountId = payload['account_id'] as String;
    final accounts = await listAccounts();
    return accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw StateError('Account $accountId not visible after connect'),
    );
  }

  /// List all connected sync accounts for the current user. Token fields are
  /// redacted server-side — this is safe to log in aggregate.
  Future<List<ConnectedSyncAccount>> listAccounts() async {
    try {
      final response = await _client.get('/sync/accounts');
      final raw = (response.data as List?) ?? const <dynamic>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ConnectedSyncAccount.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('❌ [SyncRepository] listAccounts failed: $e');
      rethrow;
    }
  }

  /// Toggle per-account preferences. At least one of the three flags must be
  /// provided — the backend returns 400 otherwise.
  Future<ConnectedSyncAccount> updateAccount(
    String accountId, {
    bool? autoImport,
    bool? importStrength,
    bool? importCardio,
  }) async {
    final body = <String, dynamic>{
      if (autoImport != null) 'auto_import': autoImport,
      if (importStrength != null) 'import_strength': importStrength,
      if (importCardio != null) 'import_cardio': importCardio,
    };
    if (body.isEmpty) {
      throw ArgumentError('updateAccount: provide at least one preference to change');
    }
    final response = await _client.patch(
      '/sync/accounts/$accountId',
      data: body,
    );
    return ConnectedSyncAccount.fromJson(response.data as Map<String, dynamic>);
  }

  /// Soft-delete (revoke) a connected account. The server sets status='revoked'
  /// and unregisters the webhook but leaves the historical rows intact for
  /// consistency if a late webhook arrives after disconnect.
  Future<void> disconnectAccount(String accountId) async {
    try {
      await _client.delete('/sync/accounts/$accountId');
      debugPrint('🛑 [SyncRepository] disconnected $accountId');
    } catch (e) {
      debugPrint('❌ [SyncRepository] disconnect failed: $e');
      rethrow;
    }
  }

  /// Force an immediate pull-sync for [accountId]. Useful after connect so
  /// the user sees results without waiting for the 15-min cron.
  Future<ManualSyncResult> manualSync(String accountId) async {
    final response = await _client.post('/sync/$accountId/manual-sync');
    return ManualSyncResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Push HealthKit-harvested workouts to the backend (iOS only).
  /// Each entry in [activities] must follow the shape documented in
  /// ``backend/services/sync/apple_health.py::receive_healthkit_sync``.
  Future<Map<String, int>> pushAppleHealth({
    required List<Map<String, dynamic>> activities,
    String? accountId,
  }) async {
    if (activities.isEmpty) {
      return const {'inserted_cardio': 0, 'inserted_strength': 0, 'total_activities': 0};
    }
    final response = await _client.post(
      '/sync/apple-health/push',
      data: {
        'activities': activities,
        if (accountId != null) 'account_id': accountId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return <String, int>{
      'inserted_cardio': (data['inserted_cardio'] as num?)?.toInt() ?? 0,
      'inserted_strength': (data['inserted_strength'] as num?)?.toInt() ?? 0,
      'total_activities': (data['total_activities'] as num?)?.toInt() ?? 0,
    };
  }

  void _assertProvider(String provider) {
    if (!allowedProviders.contains(provider)) {
      throw ArgumentError.value(
        provider,
        'provider',
        'must be one of $allowedProviders',
      );
    }
  }
}
