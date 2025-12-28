/// Represents a feature request with voting functionality (Robinhood-style)
class FeatureRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final int voteCount;
  final DateTime? releaseDate;
  final bool userHasVoted;
  final DateTime createdAt;
  final String? createdBy;

  const FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.voteCount,
    this.releaseDate,
    required this.userHasVoted,
    required this.createdAt,
    this.createdBy,
  });

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      userHasVoted: json['user_has_voted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'vote_count': voteCount,
      'release_date': releaseDate?.toIso8601String(),
      'user_has_voted': userHasVoted,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Get time remaining until release
  Duration? get timeUntilRelease {
    if (releaseDate == null) return null;
    final now = DateTime.now();
    final difference = releaseDate!.difference(now);
    return difference.isNegative ? null : difference;
  }

  /// Get formatted countdown string (Robinhood-style)
  /// Format: "XdXh" for days/hours, "XhXm" for hours/minutes, "XmXs" for minutes/seconds
  String get formattedCountdown {
    final time = timeUntilRelease;
    if (time == null) return '';

    if (time.inDays > 0) {
      final hours = time.inHours % 24;
      return '${time.inDays}d ${hours}h';
    } else if (time.inHours > 0) {
      final minutes = time.inMinutes % 60;
      return '${time.inHours}h ${minutes}m';
    } else if (time.inMinutes > 0) {
      final seconds = time.inSeconds % 60;
      return '${time.inMinutes}m ${seconds}s';
    } else {
      return '${time.inSeconds}s';
    }
  }

  /// Check if feature is planned (has release date)
  bool get isPlanned => status == 'planned' && releaseDate != null;

  /// Check if feature is in voting phase
  bool get isVoting => status == 'voting';

  /// Check if feature is in progress
  bool get inProgress => status == 'in_progress';

  /// Check if feature is released
  bool get isReleased => status == 'released';

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case 'workout':
        return 'Workout';
      case 'social':
        return 'Social';
      case 'analytics':
        return 'Analytics';
      case 'nutrition':
        return 'Nutrition';
      case 'coaching':
        return 'Coaching';
      case 'ui_ux':
        return 'UI/UX';
      case 'integration':
        return 'Integration';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case 'voting':
        return 'Voting';
      case 'planned':
        return 'Planned';
      case 'in_progress':
        return 'In Progress';
      case 'released':
        return 'Released';
      default:
        return status;
    }
  }

  /// Create a copy with updated fields
  FeatureRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    int? voteCount,
    DateTime? releaseDate,
    bool? userHasVoted,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      userHasVoted: userHasVoted ?? this.userHasVoted,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
