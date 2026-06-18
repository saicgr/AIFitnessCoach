/// A comment on a feature request (in-app feature-voting board).
///
/// Threading is expressed via [parentId] + [depth] (server-capped at 9),
/// mirroring the public roadmap's threaded comments.
class FeatureComment {
  final String id;
  final String featureId;
  final String? userId;
  final String? authorName;
  final String body;
  final String? parentId;
  final int depth;
  final DateTime createdAt;

  /// True when the current viewer authored this comment (drives the delete
  /// affordance). Set server-side from the `user_id` query param.
  final bool isOwn;

  const FeatureComment({
    required this.id,
    required this.featureId,
    required this.body,
    required this.depth,
    required this.createdAt,
    this.userId,
    this.authorName,
    this.parentId,
    this.isOwn = false,
  });

  factory FeatureComment.fromJson(Map<String, dynamic> json) {
    return FeatureComment(
      id: json['id'] as String,
      featureId: json['feature_id'] as String,
      userId: json['user_id'] as String?,
      authorName: json['author_name'] as String?,
      body: json['body'] as String,
      parentId: json['parent_id'] as String?,
      depth: json['depth'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOwn: json['is_own'] as bool? ?? false,
    );
  }

  /// Display label for the author. Falls back to a neutral label rather than
  /// exposing a raw user id.
  String get displayAuthor {
    final name = authorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return isOwn ? 'You' : 'Member';
  }
}
