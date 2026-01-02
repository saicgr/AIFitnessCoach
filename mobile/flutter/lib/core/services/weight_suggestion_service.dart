/// Weight Suggestion Service
///
/// Analyzes set performance (RPE, RIR, reps achieved) and suggests
/// weight adjustments for the next set to maximize workout effectiveness.
///
/// Supports both:
/// - Rule-based suggestions (fast, local)
/// - AI-powered suggestions via Gemini (smart, uses history)
library;

import 'package:dio/dio.dart';
import '../constants/app_colors.dart';

/// RPE (Rate of Perceived Exertion) scale with user-friendly descriptions
enum RpeLevel {
  rpe6(6, 'Light', 'Could do 4+ more reps easily', AppColors.success),
  rpe7(7, 'Moderate', 'Could do 3 more reps', AppColors.cyan),
  rpe8(8, 'Challenging', 'Could do 2 more reps', AppColors.orange),
  rpe9(9, 'Hard', 'Could do 1 more rep', AppColors.purple),
  rpe10(10, 'Max Effort', 'Could not do another rep', AppColors.error);

  final int value;
  final String label;
  final String description;
  final dynamic color;

  const RpeLevel(this.value, this.label, this.description, this.color);

  static RpeLevel? fromValue(int? value) {
    if (value == null) return null;
    return RpeLevel.values.where((e) => e.value == value).firstOrNull;
  }

  /// Get emoji for visual representation
  String get emoji {
    switch (this) {
      case RpeLevel.rpe6:
        return '😊';
      case RpeLevel.rpe7:
        return '🙂';
      case RpeLevel.rpe8:
        return '😤';
      case RpeLevel.rpe9:
        return '😰';
      case RpeLevel.rpe10:
        return '🔥';
    }
  }
}

/// RIR (Reps in Reserve) scale with user-friendly descriptions
enum RirLevel {
  rir0(0, 'Failure', 'No reps left in the tank'),
  rir1(1, 'Near Max', '1 rep left before failure'),
  rir2(2, 'Hard', '2 reps left before failure'),
  rir3(3, 'Moderate', '3 reps left before failure'),
  rir4(4, 'Comfortable', '4 reps left before failure'),
  rir5(5, 'Easy', '5+ reps left before failure');

  final int value;
  final String label;
  final String description;

  const RirLevel(this.value, this.label, this.description);

  static RirLevel? fromValue(int? value) {
    if (value == null) return null;
    return RirLevel.values.where((e) => e.value == value).firstOrNull;
  }

  /// Get emoji for visual representation
  String get emoji {
    switch (this) {
      case RirLevel.rir0:
        return '🔥';
      case RirLevel.rir1:
        return '😰';
      case RirLevel.rir2:
        return '😤';
      case RirLevel.rir3:
        return '🙂';
      case RirLevel.rir4:
        return '😊';
      case RirLevel.rir5:
        return '😎';
    }
  }
}

/// The type of weight adjustment suggestion
enum SuggestionType {
  increase,
  maintain,
  decrease,
}

/// A weight adjustment suggestion with reasoning
class WeightSuggestion {
  /// The suggested weight change in kg (positive = increase, negative = decrease)
  final double weightDelta;

  /// The new suggested weight
  final double suggestedWeight;

  /// The type of suggestion
  final SuggestionType type;

  /// Human-readable reason for the suggestion
  final String reason;

  /// Confidence level (0.0 to 1.0)
  final double confidence;

  /// Short motivational message
  final String encouragement;

  /// Whether this suggestion came from AI (true) or rule-based logic (false)
  final bool aiPowered;

  const WeightSuggestion({
    required this.weightDelta,
    required this.suggestedWeight,
    required this.type,
    required this.reason,
    required this.confidence,
    required this.encouragement,
    this.aiPowered = false,
  });

  /// Create from API response JSON
  factory WeightSuggestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['suggestion_type'] as String? ?? 'maintain';
    SuggestionType type;
    switch (typeStr) {
      case 'increase':
        type = SuggestionType.increase;
        break;
      case 'decrease':
        type = SuggestionType.decrease;
        break;
      default:
        type = SuggestionType.maintain;
    }

    return WeightSuggestion(
      weightDelta: (json['weight_delta'] as num?)?.toDouble() ?? 0.0,
      suggestedWeight: (json['suggested_weight'] as num?)?.toDouble() ?? 0.0,
      type: type,
      reason: json['reason'] as String? ?? 'Based on your performance.',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      encouragement: json['encouragement'] as String? ?? 'Keep it up!',
      aiPowered: json['ai_powered'] as bool? ?? true,
    );
  }

  /// Check if this is a "no change" suggestion
  bool get isNoChange => type == SuggestionType.maintain;

  /// Get the formatted weight change string
  String get formattedDelta {
    if (weightDelta == 0) return 'Keep weight';
    final sign = weightDelta > 0 ? '+' : '';
    return '$sign${weightDelta.toStringAsFixed(1)} kg';
  }
}

/// Service for generating weight suggestions based on set performance
class WeightSuggestionService {
  /// Get AI-powered weight suggestion from the backend
  ///
  /// This method calls the Gemini-powered API endpoint for intelligent
  /// weight suggestions that consider:
  /// - Current set performance
  /// - Historical workout data for this exercise
  /// - User's fitness level and goals
  /// - Equipment-specific weight increments
  ///
  /// Falls back to [generateSuggestion] if the API call fails.
  static Future<WeightSuggestion?> getAISuggestion({
    required Dio dio,
    required String userId,
    required String exerciseName,
    String? exerciseId,
    required String equipment,
    required String muscleGroup,
    required int setNumber,
    required int totalSets,
    required int repsCompleted,
    required int targetReps,
    required double weightKg,
    int? rpe,
    int? rir,
    bool isLastSet = false,
    String fitnessLevel = 'intermediate',
    List<String> goals = const [],
  }) async {
    try {
      final response = await dio.post(
        '/workouts/weight-suggestion',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'exercise_id': exerciseId,
          'equipment': equipment,
          'muscle_group': muscleGroup,
          'current_set': {
            'set_number': setNumber,
            'reps_completed': repsCompleted,
            'target_reps': targetReps,
            'weight_kg': weightKg,
            'rpe': rpe,
            'rir': rir,
          },
          'total_sets': totalSets,
          'is_last_set': isLastSet,
          'fitness_level': fitnessLevel,
          'goals': goals,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return WeightSuggestion.fromJson(response.data as Map<String, dynamic>);
      }

      // API returned non-200, fall back to rule-based
      return null;
    } catch (e) {
      // Log error and fall back to rule-based
      print('❌ [WeightSuggestion] AI suggestion failed: $e');
      return null;
    }
  }

  /// Generate a weight suggestion based on completed set performance (rule-based)
  ///
  /// This is the fast, local fallback used when:
  /// - AI API is unavailable
  /// - User doesn't have RPE/RIR data
  /// - Need instant response without network call
  ///
  /// Parameters:
  /// - [currentWeight]: The weight used in the completed set
  /// - [targetReps]: The target number of reps for the set
  /// - [actualReps]: The actual number of reps completed
  /// - [rpe]: Rate of Perceived Exertion (6-10)
  /// - [rir]: Reps in Reserve (0-5)
  /// - [equipmentIncrement]: The smallest weight increment for the equipment
  /// - [isLastSet]: Whether this is the last set of the exercise
  static WeightSuggestion? generateSuggestion({
    required double currentWeight,
    required int targetReps,
    required int actualReps,
    int? rpe,
    int? rir,
    double equipmentIncrement = 2.5,
    bool isLastSet = false,
  }) {
    // Need at least RPE or RIR to make a suggestion
    if (rpe == null && rir == null) {
      return null;
    }

    // Calculate rep performance ratio
    final repRatio = targetReps > 0 ? actualReps / targetReps : 1.0;

    // Determine effort level (use RIR if available, otherwise convert RPE)
    int effectiveRir;
    if (rir != null) {
      effectiveRir = rir;
    } else if (rpe != null) {
      // Convert RPE to approximate RIR (RPE 10 = RIR 0, RPE 6 = RIR 4)
      effectiveRir = (10 - rpe).clamp(0, 5);
    } else {
      return null;
    }

    // Decision logic based on RIR and rep achievement
    SuggestionType type;
    double weightDelta;
    String reason;
    String encouragement;
    double confidence;

    if (effectiveRir >= 4 && repRatio >= 1.0) {
      // Very easy set, hit all reps with lots left in tank
      type = SuggestionType.increase;
      weightDelta = equipmentIncrement * 2; // Double increment
      reason = 'That set was too easy! You had $effectiveRir+ reps left.';
      encouragement = 'Time to level up! 💪';
      confidence = 0.9;
    } else if (effectiveRir >= 3 && repRatio >= 1.0) {
      // Easy set, hit all reps comfortably
      type = SuggestionType.increase;
      weightDelta = equipmentIncrement;
      reason = 'Great form with $effectiveRir reps in reserve.';
      encouragement = 'Let\'s push a bit harder!';
      confidence = 0.85;
    } else if (effectiveRir >= 2 && repRatio >= 0.9) {
      // Good working set, near target
      type = SuggestionType.maintain;
      weightDelta = 0;
      reason = 'Perfect intensity! Keep this weight.';
      encouragement = 'You\'re in the zone! 🎯';
      confidence = 0.9;
    } else if (effectiveRir == 1 && repRatio >= 0.8) {
      // Hard set, close to failure
      if (isLastSet) {
        // Last set - this is actually ideal
        type = SuggestionType.maintain;
        weightDelta = 0;
        reason = 'Pushed hard on the last set - perfect!';
        encouragement = 'Great finish! 🔥';
        confidence = 0.85;
      } else {
        // Not last set - might want to back off slightly
        type = SuggestionType.maintain;
        weightDelta = 0;
        reason = 'Working hard! Save some energy for remaining sets.';
        encouragement = 'Stay strong!';
        confidence = 0.7;
      }
    } else if (effectiveRir == 0 || repRatio < 0.7) {
      // Failed or struggled significantly
      type = SuggestionType.decrease;
      weightDelta = -equipmentIncrement;
      reason = repRatio < 0.7
          ? 'Missed ${((1 - repRatio) * targetReps).round()} reps. Lower weight to hit targets.'
          : 'Hit failure. Reduce weight to maintain form.';
      encouragement = 'Smart training is sustainable training.';
      confidence = 0.85;
    } else if (repRatio < 0.85) {
      // Missed some reps but not too many
      type = SuggestionType.maintain;
      weightDelta = 0;
      reason = 'Slightly under target. Keep weight and focus on form.';
      encouragement = 'You\'ve got this!';
      confidence = 0.75;
    } else {
      // Default - maintain weight
      type = SuggestionType.maintain;
      weightDelta = 0;
      reason = 'Good effort. Maintain current weight.';
      encouragement = 'Keep pushing!';
      confidence = 0.7;
    }

    // Calculate suggested weight
    final suggestedWeight = (currentWeight + weightDelta).clamp(0.0, 999.0);

    // If we're at 0 weight (bodyweight exercises), don't suggest weight changes
    if (currentWeight == 0 && suggestedWeight == 0) {
      return WeightSuggestion(
        weightDelta: 0,
        suggestedWeight: 0,
        type: SuggestionType.maintain,
        reason: 'Bodyweight exercise - focus on form and reps.',
        confidence: 0.9,
        encouragement: 'Keep that form tight!',
      );
    }

    return WeightSuggestion(
      weightDelta: weightDelta,
      suggestedWeight: suggestedWeight,
      type: type,
      reason: reason,
      confidence: confidence,
      encouragement: encouragement,
    );
  }

  /// Get a user-friendly description for an RPE value
  static String getRpeDescription(int rpe) {
    return RpeLevel.fromValue(rpe)?.description ?? 'Unknown intensity';
  }

  /// Get a user-friendly label for an RPE value
  static String getRpeLabel(int rpe) {
    return RpeLevel.fromValue(rpe)?.label ?? 'RPE $rpe';
  }

  /// Get emoji for an RPE value
  static String getRpeEmoji(int rpe) {
    return RpeLevel.fromValue(rpe)?.emoji ?? '🏋️';
  }

  /// Get a user-friendly description for a RIR value
  static String getRirDescription(int rir) {
    return RirLevel.fromValue(rir)?.description ?? 'Unknown reserve';
  }

  /// Get a user-friendly label for a RIR value
  static String getRirLabel(int rir) {
    return RirLevel.fromValue(rir)?.label ?? '$rir RIR';
  }

  /// Get emoji for a RIR value
  static String getRirEmoji(int rir) {
    return RirLevel.fromValue(rir)?.emoji ?? '💪';
  }
}
