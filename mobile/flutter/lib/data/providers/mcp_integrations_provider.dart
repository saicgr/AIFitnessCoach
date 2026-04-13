import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcp_integration.dart';
import '../services/api_client.dart';

/// Riverpod state + provider for the "AI Integrations" settings screen.
///
/// Talks to:
///   GET    /api/v1/users/me/mcp-integrations                 — list (PAT+OAuth)
///   POST   /api/v1/users/me/mcp-integrations/pat             — create PAT
///   DELETE /api/v1/users/me/mcp-integrations/pat/{token_id}  — revoke PAT
///   DELETE /api/v1/users/me/mcp-integrations/{client_id}     — revoke OAuth
///
/// Uses StateNotifier to match conventions already established by providers
/// like `email_preferences_provider.dart` — loading/error/data in one
/// unified state, per-item mutations that don't trigger a full refresh.

// ============================================
// STATE
// ============================================

@immutable
class McpIntegrationsState {
  /// Active integrations (PAT + OAuth, server-side merged).
  final List<McpIntegration> integrations;

  /// True while any network fetch is in flight (initial load or refresh).
  final bool isLoading;

  /// id of the integration currently being disconnected (PAT token_id or
  /// OAuth client_id), or null. Used so the list can show a per-row spinner
  /// without blocking other rows.
  final String? disconnectingId;

  /// True while a PAT is being generated. Separate flag so the main list
  /// isn't locked during creation.
  final bool isCreating;

  /// Human-readable error message from the most recent failed operation.
  final String? error;

  /// True once the initial load has completed (success OR error). Prevents
  /// the empty-state UI from flashing before the first fetch returns.
  final bool hasLoadedOnce;

  const McpIntegrationsState({
    this.integrations = const [],
    this.isLoading = false,
    this.disconnectingId,
    this.isCreating = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  McpIntegrationsState copyWith({
    List<McpIntegration>? integrations,
    bool? isLoading,
    String? disconnectingId,
    bool? isCreating,
    String? error,
    bool clearError = false,
    bool clearDisconnecting = false,
    bool? hasLoadedOnce,
  }) {
    return McpIntegrationsState(
      integrations: integrations ?? this.integrations,
      isLoading: isLoading ?? this.isLoading,
      disconnectingId: clearDisconnecting
          ? null
          : (disconnectingId ?? this.disconnectingId),
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  bool get isEmpty => integrations.isEmpty;
}

// ============================================
// NOTIFIER
// ============================================

class McpIntegrationsNotifier extends StateNotifier<McpIntegrationsState> {
  final ApiClient _client;

  McpIntegrationsNotifier(this._client) : super(const McpIntegrationsState()) {
    load();
  }

  // ─── LIST ──────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔌 [MCPIntegrations] Loading integrations...');
      final response = await _client.get('/users/me/mcp-integrations');
      final raw = response.data;
      final list = raw is List ? raw : const [];

      final parsed = list
          .whereType<Map>()
          .map((m) => McpIntegration.fromJson(Map<String, dynamic>.from(m)))
          // Drop rows without an id — can't revoke them anyway.
          .where((i) => i.id.isNotEmpty)
          .toList(growable: false);

      state = state.copyWith(
        integrations: parsed,
        isLoading: false,
        hasLoadedOnce: true,
      );
      debugPrint('✅ [MCPIntegrations] Loaded ${parsed.length} integration(s)');
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      debugPrint('❌ [MCPIntegrations] Load failed: $msg');
      state = state.copyWith(
        isLoading: false,
        error: msg,
        hasLoadedOnce: true,
      );
    } catch (e) {
      debugPrint('❌ [MCPIntegrations] Load failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load integrations. Please try again.',
        hasLoadedOnce: true,
      );
    }
  }

  // ─── CREATE PAT ────────────────────────────────────────────────────────

  /// Generate a new PAT. Returns the full creation payload (including the
  /// plaintext token — it's the only time it's available) on success, or
  /// null on failure. The caller shows a "Connection Ready" sheet from the
  /// returned value.
  ///
  /// Pass `scopes: null` for Quick Setup (backend defaults); pass an
  /// explicit list for Custom Setup. The backend validates against the
  /// master scope list so frontend doesn't need to mirror that.
  Future<McpPatCreation?> createPat({
    required String name,
    List<String>? scopes,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: 'Please give this connection a name.');
      return null;
    }

    state = state.copyWith(isCreating: true, clearError: true);
    try {
      debugPrint('🔌 [MCPIntegrations] Creating PAT "$trimmed"...');
      final response = await _client.post(
        '/users/me/mcp-integrations/pat',
        data: {
          'name': trimmed,
          if (scopes != null) 'scopes': scopes,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw StateError('Unexpected response shape');
      }
      final created =
          McpPatCreation.fromJson(Map<String, dynamic>.from(data));

      // Reload the list so the new row appears immediately. Fire and forget.
      load();

      state = state.copyWith(isCreating: false);
      debugPrint('✅ [MCPIntegrations] PAT created: ${created.tokenId}');
      return created;
    } on DioException catch (e) {
      // 402 = subscription gate — surface the upgrade URL if present.
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String msg;
      if (status == 402 && data is Map) {
        final detail = data['detail'];
        msg = (detail is Map && detail['error_description'] is String)
            ? detail['error_description'] as String
            : 'A yearly subscription is required to create connections.';
      } else {
        msg = _dioErrorMessage(e);
      }
      debugPrint('❌ [MCPIntegrations] Create PAT failed ($status): $msg');
      state = state.copyWith(isCreating: false, error: msg);
      return null;
    } catch (e) {
      debugPrint('❌ [MCPIntegrations] Create PAT failed: $e');
      state = state.copyWith(
        isCreating: false,
        error: 'Failed to create connection. Please try again.',
      );
      return null;
    }
  }

  // ─── REVOKE ────────────────────────────────────────────────────────────

  /// Revoke any integration regardless of type. Dispatches to the correct
  /// endpoint based on [integration.authType].
  Future<bool> disconnect(McpIntegration integration) async {
    if (integration.id.isEmpty) {
      debugPrint('⚠️ [MCPIntegrations] disconnect called with empty id');
      return false;
    }

    state = state.copyWith(
      disconnectingId: integration.id,
      clearError: true,
    );

    // PATs and OAuth clients use different DELETE paths.
    final path = integration.authType == McpIntegrationAuthType.pat
        ? '/users/me/mcp-integrations/pat/${integration.id}'
        : '/users/me/mcp-integrations/${integration.id}';

    try {
      debugPrint('🔌 [MCPIntegrations] Revoking ${integration.authType.name} '
          'id=${integration.id}...');
      await _client.delete(path);

      // Optimistic remove; matches the snappy UX the existing code had.
      final updated = state.integrations
          .where((i) =>
              !(i.id == integration.id && i.authType == integration.authType))
          .toList(growable: false);

      state = state.copyWith(
        integrations: updated,
        clearDisconnecting: true,
      );
      debugPrint('✅ [MCPIntegrations] Revoked');
      return true;
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      debugPrint('❌ [MCPIntegrations] Revoke failed: $msg');
      state = state.copyWith(
        clearDisconnecting: true,
        error: msg,
      );
      return false;
    } catch (e) {
      debugPrint('❌ [MCPIntegrations] Revoke failed: $e');
      state = state.copyWith(
        clearDisconnecting: true,
        error: 'Failed to disconnect. Please try again.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Please sign in again to manage integrations.';
    }
    if (status == 503) {
      return 'MCP integrations are temporarily unavailable.';
    }
    return 'Network error. Please check your connection and try again.';
  }
}

// ============================================
// PROVIDERS
// ============================================

final mcpIntegrationsProvider = StateNotifierProvider.autoDispose<
    McpIntegrationsNotifier, McpIntegrationsState>((ref) {
  return McpIntegrationsNotifier(ref.watch(apiClientProvider));
});
