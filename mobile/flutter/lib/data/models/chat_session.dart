/// A single "Ask Coach" conversation thread (like a ChatGPT/Gemini chat).
///
/// Plain hand-written model — NO codegen / `.g.dart` (build_runner is
/// forbidden in this repo per project_codegen_gotcha.md). Mirrors the
/// `GET /coach/sessions` item shape:
///   { id, title (nullable), preview, is_archived, message_count,
///     created_at, updated_at, last_message_at }
///
/// `title` is generated server-side asynchronously (~1-2s after the first
/// message), so it can be null right after a session is adopted on first
/// send — [displayTitle] falls back to "New chat" in that window.
class ChatSession {
  final String id;
  final String? title;
  final String preview;
  final bool isArchived;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  const ChatSession({
    required this.id,
    this.title,
    this.preview = '',
    this.isArchived = false,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  /// Title to show in the list/header — never null so the UI can render it
  /// before the server-side title generation lands.
  String get displayTitle {
    final t = title?.trim();
    return (t == null || t.isEmpty) ? 'New chat' : t;
  }

  /// Best timestamp to sort/relative-format by — newest activity first.
  DateTime? get sortTime => lastMessageAt ?? updatedAt ?? createdAt;

  static DateTime? _parseTs(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        // PostgreSQL timestamp form: "2025-12-16 00:19:09+00".
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      } catch (_) {
        return null;
      }
    }
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'].toString(),
      title: json['title'] as String?,
      preview: (json['preview'] as String?) ?? '',
      isArchived: (json['is_archived'] as bool?) ?? false,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
      lastMessageAt: _parseTs(json['last_message_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'preview': preview,
        'is_archived': isArchived,
        'message_count': messageCount,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'last_message_at': lastMessageAt?.toIso8601String(),
      };

  ChatSession copyWith({
    String? title,
    String? preview,
    bool? isArchived,
    int? messageCount,
    DateTime? lastMessageAt,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      isArchived: isArchived ?? this.isArchived,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
