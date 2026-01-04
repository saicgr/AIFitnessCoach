/// Smart Weight Suggestion Model
///
/// Represents an AI-powered weight suggestion based on:
/// - User's 1RM (one-rep max) for the exercise
/// - Target intensity for training goal (hypertrophy, strength, etc.)
/// - Performance modifier from last session (RPE-based adjustments)
/// - Equipment-aware rounding
library;

/// Training goal types that determine target intensity percentage
enum TrainingGoal {
  strength('strength', 'Strength', '85-95% 1RM, 1-5 reps'),
  hypertrophy('hypertrophy', 'Hypertrophy', '65-80% 1RM, 8-12 reps'),
  endurance('endurance', 'Endurance', '50-65% 1RM, 15-20+ reps'),
  power('power', 'Power', '70-85% 1RM, 3-6 reps');

  final String value;
  final String label;
  final String description;

  const TrainingGoal(this.value, this.label, this.description);

  static TrainingGoal fromString(String value) {
    return TrainingGoal.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => TrainingGoal.hypertrophy,
    );
  }
}

/// Data from the user's last session with this exercise
class LastSessionData {
  /// Weight used in last session (kg)
  final double weightKg;

  /// Reps completed in last session
  final int reps;

  /// Rate of Perceived Exertion (6-10)
  final int? rpe;

  /// Reps in Reserve (0-5)
  final int? rir;

  /// Date of last session (ISO string)
  final String date;

  /// Workout ID from last session
  final String? workoutId;

  const LastSessionData({
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.rir,
    required this.date,
    this.workoutId,
  });

  factory LastSessionData.fromJson(Map<String, dynamic> json) {
    return LastSessionData(
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      rpe: json['rpe'] as int?,
      rir: json['rir'] as int?,
      date: json['date'] as String? ?? '',
      workoutId: json['workout_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight_kg': weightKg,
      'reps': reps,
      'rpe': rpe,
      'rir': rir,
      'date': date,
      'workout_id': workoutId,
    };
  }

  /// Format the date as a relative time (e.g., "2 days ago")
  String get formattedDate {
    try {
      final parsed = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      }
    } catch (_) {
      return date;
    }
  }
}

/// Smart weight suggestion from the AI
class SmartWeightSuggestion {
  /// The suggested weight in kg
  final double suggestedWeight;

  /// Human-readable explanation of the suggestion
  final String reasoning;

  /// Confidence level (0.0 to 1.0)
  final double confidence;

  /// Data from the last session (if available)
  final LastSessionData? lastSessionData;

  /// User's estimated 1RM for this exercise (if available)
  final double? oneRmKg;

  /// Target intensity percentage (0.0 to 1.0)
  final double targetIntensity;

  /// Training goal used for calculation
  final TrainingGoal trainingGoal;

  /// Equipment weight increment (for rounding)
  final double equipmentIncrement;

  /// Performance modifier applied (1.0 = no change)
  final double performanceModifier;

  const SmartWeightSuggestion({
    required this.suggestedWeight,
    required this.reasoning,
    required this.confidence,
    this.lastSessionData,
    this.oneRmKg,
    required this.targetIntensity,
    required this.trainingGoal,
    required this.equipmentIncrement,
    required this.performanceModifier,
  });

  factory SmartWeightSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartWeightSuggestion(
      suggestedWeight: (json['suggested_weight'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      lastSessionData: json['last_session_data'] != null
          ? LastSessionData.fromJson(
              json['last_session_data'] as Map<String, dynamic>)
          : null,
      oneRmKg: (json['one_rm_kg'] as num?)?.toDouble(),
      targetIntensity: (json['target_intensity'] as num?)?.toDouble() ?? 0.75,
      trainingGoal:
          TrainingGoal.fromString(json['training_goal'] as String? ?? 'hypertrophy'),
      equipmentIncrement:
          (json['equipment_increment'] as num?)?.toDouble() ?? 2.5,
      performanceModifier:
          (json['performance_modifier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggested_weight': suggestedWeight,
      'reasoning': reasoning,
      'confidence': confidence,
      'last_session_data': lastSessionData?.toJson(),
      'one_rm_kg': oneRmKg,
      'target_intensity': targetIntensity,
      'training_goal': trainingGoal.value,
      'equipment_increment': equipmentIncrement,
      'performance_modifier': performanceModifier,
    };
  }

  /// Whether this suggestion has sufficient confidence to auto-fill
  bool get isHighConfidence => confidence >= 0.7;

  /// Whether this suggestion should show the AI badge
  bool get shouldShowAiBadge => suggestedWeight > 0 && confidence > 0;

  /// Human-readable confidence label
  String get confidenceLabel {
    if (confidence >= 0.85) return 'High';
    if (confidence >= 0.70) return 'Good';
    if (confidence >= 0.50) return 'Moderate';
    return 'Low';
  }

  /// Format the suggested weight with unit
  String formattedWeight({bool useKg = true}) {
    if (suggestedWeight == 0) return '-';
    final unit = useKg ? 'kg' : 'lbs';
    final weight = useKg ? suggestedWeight : suggestedWeight * 2.205;
    return '${weight.toStringAsFixed(1)} $unit';
  }

  /// Get a short summary of the suggestion source
  String get sourceSummary {
    if (oneRmKg != null && oneRmKg! > 0) {
      return '${(targetIntensity * 100).toStringAsFixed(0)}% of 1RM';
    }
    if (lastSessionData != null) {
      return 'Based on last session';
    }
    return 'Initial suggestion';
  }

  /// Whether the suggestion indicates to increase weight
  bool get isIncrease => performanceModifier > 1.0;

  /// Whether the suggestion indicates to decrease weight
  bool get isDecrease => performanceModifier < 1.0;

  /// Get the modifier description
  String? get modifierDescription {
    if (performanceModifier > 1.0) {
      final pct = ((performanceModifier - 1) * 100).toStringAsFixed(0);
      return '+$pct% based on easy last session';
    } else if (performanceModifier < 1.0) {
      final pct = ((1 - performanceModifier) * 100).toStringAsFixed(0);
      return '-$pct% based on hard last session';
    }
    return null;
  }

  @override
  String toString() {
    return 'SmartWeightSuggestion('
        'weight: ${suggestedWeight}kg, '
        'confidence: ${(confidence * 100).toStringAsFixed(0)}%, '
        'goal: ${trainingGoal.label}'
        ')';
  }
}
