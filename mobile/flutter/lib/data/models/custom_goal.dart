/// Custom Goal model for user-defined training objectives.
///
/// Custom goals allow users to specify specific skills or objectives
/// (e.g., "Improve box jump height", "Train for a marathon").
/// Gemini AI generates search keywords that are used to find relevant exercises.
class CustomGoal {
  /// Unique identifier
  final String id;

  /// User who owns this goal
  final String userId;

  /// Natural language goal text (e.g., "Improve box jump height")
  final String goalText;

  /// AI-generated search keywords for RAG exercise selection
  final List<String> searchKeywords;

  /// Goal type: 'skill', 'power', 'endurance', 'sport', 'flexibility', etc.
  final String goalType;

  /// Progression strategy: 'linear', 'wave', 'periodized', 'skill_based'
  final String progressionStrategy;

  /// Exercise categories this goal targets
  final List<String> exerciseCategories;

  /// Primary muscle groups involved
  final List<String> muscleGroups;

  /// Target metrics (e.g., {"box_jump_height": "increase by 4-6 inches"})
  final Map<String, dynamic> targetMetrics;

  /// AI-generated training notes and recommendations
  final String? trainingNotes;

  /// Whether this goal is currently active
  final bool isActive;

  /// Priority 1-5 (higher = more focus in workout generation)
  final int priority;

  /// When the goal was created
  final DateTime? createdAt;

  const CustomGoal({
    required this.id,
    required this.userId,
    required this.goalText,
    required this.searchKeywords,
    required this.goalType,
    required this.progressionStrategy,
    required this.exerciseCategories,
    required this.muscleGroups,
    required this.targetMetrics,
    this.trainingNotes,
    required this.isActive,
    required this.priority,
    this.createdAt,
  });

  /// Create from JSON response
  factory CustomGoal.fromJson(Map<String, dynamic> json) {
    return CustomGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalText: json['goal_text'] as String,
      searchKeywords: _parseStringList(json['search_keywords']),
      goalType: json['goal_type'] as String? ?? 'general',
      progressionStrategy: json['progression_strategy'] as String? ?? 'linear',
      exerciseCategories: _parseStringList(json['exercise_categories']),
      muscleGroups: _parseStringList(json['muscle_groups']),
      targetMetrics: _parseMap(json['target_metrics']),
      trainingNotes: json['training_notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 3,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_text': goalText,
      'search_keywords': searchKeywords,
      'goal_type': goalType,
      'progression_strategy': progressionStrategy,
      'exercise_categories': exerciseCategories,
      'muscle_groups': muscleGroups,
      'target_metrics': targetMetrics,
      'training_notes': trainingNotes,
      'is_active': isActive,
      'priority': priority,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  CustomGoal copyWith({
    String? id,
    String? userId,
    String? goalText,
    List<String>? searchKeywords,
    String? goalType,
    String? progressionStrategy,
    List<String>? exerciseCategories,
    List<String>? muscleGroups,
    Map<String, dynamic>? targetMetrics,
    String? trainingNotes,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
  }) {
    return CustomGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalText: goalText ?? this.goalText,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      goalType: goalType ?? this.goalType,
      progressionStrategy: progressionStrategy ?? this.progressionStrategy,
      exerciseCategories: exerciseCategories ?? this.exerciseCategories,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      targetMetrics: targetMetrics ?? this.targetMetrics,
      trainingNotes: trainingNotes ?? this.trainingNotes,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper to parse list fields that could be List or JSON string
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      // Try to parse as JSON
      try {
        final decoded = value.startsWith('[')
            ? value
                .substring(1, value.length - 1)
                .split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty)
                .toList()
            : [value];
        return decoded;
      } catch (_) {
        return [value];
      }
    }
    return [];
  }

  /// Helper to parse map fields
  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  @override
  String toString() {
    return 'CustomGoal(id: $id, goalText: $goalText, goalType: $goalType, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Request model for creating a new custom goal
class CreateCustomGoalRequest {
  final String userId;
  final String goalText;
  final int priority;

  const CreateCustomGoalRequest({
    required this.userId,
    required this.goalText,
    this.priority = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'goal_text': goalText,
      'priority': priority,
    };
  }
}

/// Request model for updating a custom goal
class UpdateCustomGoalRequest {
  final bool? isActive;
  final int? priority;

  const UpdateCustomGoalRequest({
    this.isActive,
    this.priority,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (isActive != null) map['is_active'] = isActive;
    if (priority != null) map['priority'] = priority;
    return map;
  }
}
