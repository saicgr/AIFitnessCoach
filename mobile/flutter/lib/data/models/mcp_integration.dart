/// MCP Integration model.
///
/// Represents a way to access the user's FitWiz data from an external AI
/// client (Claude Desktop, ChatGPT, Cursor, etc.). Two kinds, both live in
/// the same list:
///
///   * `pat`   — Personal Access Token: user-generated, never-expires, the
///     default path (Settings → AI Integrations → Create Connection).
///   * `oauth` — OAuth client: third-party marketplace integration
///     (ChatGPT Apps, Claude Connector store). Future-facing.
///
/// The backend merges both into the GET response with a stable shape:
///     { auth_type, id, name, scopes, created_at, last_used_at }
///
/// `id` means different things per `auth_type`:
///   - `pat`   → token_id (pass to DELETE /pat/{token_id})
///   - `oauth` → client_id (pass to DELETE /{client_id})
///
/// Using plain Dart classes matches project convention
/// (see `email_preferences.dart`, `custom_goal.dart`, etc.).
library;

enum McpIntegrationAuthType {
  /// User-created personal access token.
  pat,

  /// Third-party OAuth client (Claude Desktop, marketplaces).
  oauth,
}

McpIntegrationAuthType _parseAuthType(String? raw) {
  switch (raw) {
    case 'oauth':
      return McpIntegrationAuthType.oauth;
    case 'pat':
    default:
      // Default to PAT so unknown/old rows don't render as OAuth and show
      // the wrong DELETE endpoint.
      return McpIntegrationAuthType.pat;
  }
}

class McpIntegration {
  /// How this integration is authenticated — affects revoke endpoint shape.
  final McpIntegrationAuthType authType;

  /// Unified identifier — `token_id` for PATs, `client_id` for OAuth.
  final String id;

  /// Display name. For PATs this is user-chosen ("My Laptop Claude"),
  /// for OAuth it's the client's self-declared name ("Claude Desktop").
  final String name;

  /// Scopes granted. Same wire format for both types.
  final List<String> scopes;

  /// When the integration was created (PAT generated or OAuth consent given).
  final DateTime createdAt;

  /// When a tool call was last made with this token. Null if never used.
  final DateTime? lastUsedAt;

  const McpIntegration({
    required this.authType,
    required this.id,
    required this.name,
    required this.scopes,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Parse a JSON object from `GET /api/v1/users/me/mcp-integrations`.
  ///
  /// Defensive: malformed timestamps fall back to `now()`, missing name
  /// falls back to "Connection", non-list scopes become empty. Nothing
  /// here is load-bearing for revoke — revoke uses `id` + `authType` only.
  factory McpIntegration.fromJson(Map<String, dynamic> json) {
    final rawScopes = json['scopes'];
    final scopes = rawScopes is List
        ? rawScopes.map((s) => s.toString()).toList(growable: false)
        : const <String>[];

    DateTime parsedCreatedAt;
    try {
      final raw = json['created_at'] as String?;
      parsedCreatedAt = raw != null ? DateTime.parse(raw) : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedLastUsedAt;
    final lastUsedRaw = json['last_used_at'];
    if (lastUsedRaw is String && lastUsedRaw.isNotEmpty) {
      try {
        parsedLastUsedAt = DateTime.parse(lastUsedRaw);
      } catch (_) {
        parsedLastUsedAt = null;
      }
    }

    return McpIntegration(
      authType: _parseAuthType(json['auth_type'] as String?),
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Connection',
      scopes: scopes,
      createdAt: parsedCreatedAt,
      lastUsedAt: parsedLastUsedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'auth_type': authType == McpIntegrationAuthType.oauth ? 'oauth' : 'pat',
        'id': id,
        'name': name,
        'scopes': scopes,
        'created_at': createdAt.toIso8601String(),
        'last_used_at': lastUsedAt?.toIso8601String(),
      };

  McpIntegration copyWith({
    McpIntegrationAuthType? authType,
    String? id,
    String? name,
    List<String>? scopes,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) =>
      McpIntegration(
        authType: authType ?? this.authType,
        id: id ?? this.id,
        name: name ?? this.name,
        scopes: scopes ?? this.scopes,
        createdAt: createdAt ?? this.createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is McpIntegration &&
        other.authType == authType &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode => Object.hash(authType, id, name, createdAt, lastUsedAt);

  @override
  String toString() =>
      'McpIntegration(${authType.name} $name/$id, scopes=${scopes.length}, '
      'created=$createdAt, lastUsed=$lastUsedAt)';
}


/// Response from `POST /api/v1/users/me/mcp-integrations/pat` — shown once
/// in the "Connection Ready" sheet. The `token` plaintext is never
/// retrievable again; the UI must show it prominently and offer Copy.
class McpPatCreation {
  final String tokenId;
  final String name;
  final List<String> scopes;

  /// The plaintext PAT, e.g. `fwz_pat_abc...`. Only returned at creation time.
  final String token;

  final DateTime createdAt;

  /// Pre-built JSON config the user pastes into Claude/ChatGPT/Cursor.
  /// Server constructs it so the Flutter client doesn't need to know the
  /// MCP server URL. Rendered as pretty-printed JSON in the UI.
  final Map<String, dynamic> connectionConfig;

  const McpPatCreation({
    required this.tokenId,
    required this.name,
    required this.scopes,
    required this.token,
    required this.createdAt,
    required this.connectionConfig,
  });

  factory McpPatCreation.fromJson(Map<String, dynamic> json) {
    final rawScopes = json['scopes'];
    final scopes = rawScopes is List
        ? rawScopes.map((s) => s.toString()).toList(growable: false)
        : const <String>[];

    DateTime parsedCreatedAt;
    try {
      final raw = json['created_at'] as String?;
      parsedCreatedAt = raw != null ? DateTime.parse(raw) : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    final rawConfig = json['connection_config'];
    final Map<String, dynamic> config = rawConfig is Map
        ? Map<String, dynamic>.from(rawConfig)
        : <String, dynamic>{};

    return McpPatCreation(
      tokenId: (json['token_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Connection',
      scopes: scopes,
      token: (json['token'] as String?) ?? '',
      createdAt: parsedCreatedAt,
      connectionConfig: config,
    );
  }
}
