/// Models for the "What Coach Remembers" surface — the long-term memories the
/// AI coach has noted about the user, plus the per-user master enable toggle.
///
/// Hand-written `fromJson` (NO freezed / json_serializable codegen): the repo's
/// build_runner is intentionally never run here (Flutter pinned, `.g.dart`
/// committed), so a generated part file would never be regenerated.
library;

/// One long-term memory the coach has stored about the user.
///
/// Mirrors a row from `GET /coach/memory`'s `items` array. Every field is
/// defensively parsed so a partial / null-bearing payload never throws — the
/// list surface tolerates older rows that predate newer columns.
class CoachMemory {
  /// Stable server id — used for PATCH / resolve / DELETE.
  final String id;

  /// One of: semantic | episodic | state | derived. Drives the friendly group
  /// heading. Unknown values fall back to a generic "Other" bucket.
  final String memoryType;

  /// Free-form category label the backend assigned (e.g. "nutrition",
  /// "injury", "schedule"). Shown as a chip. May be empty.
  final String category;

  /// The actual remembered fact, shown to the user and editable inline.
  final String content;

  /// One of: provisional | active | open | resolved | superseded | dismissed.
  /// `open` items are "following up" loops the coach is still tracking.
  final String status;

  /// 0..1 importance weight the backend assigns. Used only for sort ordering
  /// (higher = more salient). Defaults to 0 when absent.
  final double salience;

  /// Whether this memory touches sensitive / health data — surfaces a lock
  /// glyph so the user knows it is handled with extra care.
  final bool sensitive;

  /// The original user phrasing the memory was derived from, if the backend
  /// captured it. Shown as supporting context under the content. May be null.
  final String? sourceQuote;

  /// For `open` loops, the question the coach intends to follow up on. May be
  /// null for non-loop memories.
  final String? resolutionPrompt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CoachMemory({
    required this.id,
    required this.memoryType,
    required this.category,
    required this.content,
    required this.status,
    required this.salience,
    required this.sensitive,
    this.sourceQuote,
    this.resolutionPrompt,
    this.createdAt,
    this.updatedAt,
  });

  /// True when this is an open loop the coach is still following up on.
  bool get isOpenLoop => status == 'open';

  /// True when the memory has been closed out (resolved / superseded /
  /// dismissed) — only shown when `includeResolved` is requested.
  bool get isResolved =>
      status == 'resolved' ||
      status == 'superseded' ||
      status == 'dismissed';

  factory CoachMemory.fromJson(Map<String, dynamic> json) {
    return CoachMemory(
      id: (json['id'] ?? '').toString(),
      memoryType: (json['memory_type'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      salience: _parseDouble(json['salience']),
      sensitive: _parseBool(json['sensitive']),
      sourceQuote: _parseNullableString(json['source_quote']),
      resolutionPrompt: _parseNullableString(json['resolution_prompt']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  CoachMemory copyWith({
    String? content,
    String? status,
  }) {
    return CoachMemory(
      id: id,
      memoryType: memoryType,
      category: category,
      content: content ?? this.content,
      status: status ?? this.status,
      salience: salience,
      sensitive: sensitive,
      sourceQuote: sourceQuote,
      resolutionPrompt: resolutionPrompt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  static String? _parseNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

/// Full payload from `GET /coach/memory`: the enabled flag, a total count, and
/// the list of memories. `enabled` is echoed here so the list response and the
/// settings response can never drift apart.
class CoachMemoryList {
  final bool enabled;
  final int total;
  final List<CoachMemory> items;

  const CoachMemoryList({
    required this.enabled,
    required this.total,
    required this.items,
  });

  bool get isEmpty => items.isEmpty;

  factory CoachMemoryList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsed = <CoachMemory>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsed.add(
            CoachMemory.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return CoachMemoryList(
      enabled: CoachMemory._parseBool(json['enabled']),
      total: (json['total'] is num)
          ? (json['total'] as num).toInt()
          : parsed.length,
      items: parsed,
    );
  }
}
