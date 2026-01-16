/// Weight Suggestion Service
///
/// Analyzes set performance (RPE, RIR, reps achieved) and suggests
/// weight adjustments for the next set to maximize workout effectiveness.
///
/// Also provides AI-powered rest time suggestions based on:
/// - Exercise type (compound vs isolation)
/// - RPE (Rate of Perceived Exertion)
/// - Sets remaining
/// - User fitness goals
///
/// Supports both:
/// - Rule-based suggestions (fast, local)
/// - AI-powered suggestions via Gemini (smart, uses history)
library;

import 'package:dio/dio.dart';
import '../constants/app_colors.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/models/smart_weight_suggestion.dart';

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
  /// Session-level cache for smart weight suggestions
  /// Key format: "exerciseId:targetReps:goal"
  static final Map<String, SmartWeightSuggestion> _smartWeightCache = {};

  /// Clear the smart weight cache (call when starting new workout)
  static void clearSmartWeightCache() {
    _smartWeightCache.clear();
  }

  /// Get smart weight suggestion for pre-filling exercise weight
  ///
  /// This method fetches an AI-powered weight suggestion based on:
  /// - User's 1RM for this exercise (from strength_records)
  /// - Target reps and training goal (determines intensity %)
  /// - Last session performance (RPE-based modifier)
  /// - Equipment-aware rounding
  ///
  /// Results are cached per exercise per session to reduce API calls.
  ///
  /// Parameters:
  /// - [dio]: Dio instance for HTTP requests
  /// - [userId]: User ID
  /// - [exerciseId]: Exercise ID (can be empty to use name lookup)
  /// - [exerciseName]: Exercise name (used if exerciseId is empty)
  /// - [targetReps]: Target number of reps for the set
  /// - [goal]: Training goal (strength, hypertrophy, endurance, power)
  /// - [equipment]: Equipment type for weight rounding
  /// - [forceRefresh]: Skip cache and fetch fresh data
  static Future<SmartWeightSuggestion?> getSmartWeight({
    required Dio dio,
    required String userId,
    required String exerciseId,
    String? exerciseName,
    required int targetReps,
    TrainingGoal goal = TrainingGoal.hypertrophy,
    String equipment = 'dumbbell',
    bool forceRefresh = false,
  }) async {
    // Generate cache key
    final cacheKey = '$exerciseId:$targetReps:${goal.value}';

    // Check cache first (unless force refresh)
    if (!forceRefresh && _smartWeightCache.containsKey(cacheKey)) {
      print('✅ [SmartWeight] Cache hit for $cacheKey');
      return _smartWeightCache[cacheKey];
    }

    try {
      // Determine which endpoint to use
      final String endpoint;
      final Map<String, dynamic> queryParams;

      if (exerciseId.isNotEmpty) {
        endpoint = '/workouts/smart-weight/$userId/$exerciseId';
        queryParams = {
          'target_reps': targetReps,
          'goal': goal.value,
          'equipment': equipment,
        };
        if (exerciseName != null) {
          queryParams['exercise_name'] = exerciseName;
        }
      } else if (exerciseName != null && exerciseName.isNotEmpty) {
        endpoint = '/workouts/smart-weight/by-name/$userId';
        queryParams = {
          'exercise_name': exerciseName,
          'target_reps': targetReps,
          'goal': goal.value,
          'equipment': equipment,
        };
      } else {
        print('❌ [SmartWeight] No exercise ID or name provided');
        return null;
      }

      print('🔍 [SmartWeight] Fetching for $exerciseName (reps: $targetReps, goal: ${goal.value})');

      final response = await dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final suggestion = SmartWeightSuggestion.fromJson(
          response.data as Map<String, dynamic>,
        );

        // Cache the result
        _smartWeightCache[cacheKey] = suggestion;

        print('✅ [SmartWeight] Got suggestion: ${suggestion.suggestedWeight}kg '
            '(confidence: ${(suggestion.confidence * 100).toStringAsFixed(0)}%)');

        return suggestion;
      }

      print('⚠️ [SmartWeight] API returned status ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('❌ [SmartWeight] Network error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [SmartWeight] Error: $e');
      return null;
    }
  }

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
    // AI Settings for personalization
    String coachingStyle = 'motivational',
    String communicationTone = 'encouraging',
    double encouragementLevel = 0.7,
    String responseLength = 'balanced',
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
          // AI Settings
          'coaching_style': coachingStyle,
          'communication_tone': communicationTone,
          'encouragement_level': encouragementLevel,
          'response_length': responseLength,
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

  /// Adjust weight for next set based on logged RIR vs target RIR
  ///
  /// This provides instant, rules-based weight adjustment when the user
  /// logs their actual RIR after completing a set. The adjustment helps
  /// ensure the next set is appropriately challenging.
  ///
  /// Logic:
  /// - RIR higher than target = weight was too light → increase
  /// - RIR lower than target = weight was too heavy → decrease
  /// - RIR matches target = perfect weight → no change
  ///
  /// Parameters:
  /// - [currentWeight]: Weight used in the just-completed set (in kg)
  /// - [loggedRir]: The user's logged RIR (0-5)
  /// - [targetRir]: The target RIR for the set (0-5)
  /// - [incrementKg]: Equipment-specific weight increment (default 2.5kg)
  ///
  /// Returns: Adjusted weight rounded to the nearest increment
  static double adjustWeightForRir({
    required double currentWeight,
    required int loggedRir,
    required int targetRir,
    double incrementKg = 2.5,
  }) {
    // Skip adjustment for bodyweight exercises
    if (currentWeight == 0) return 0;

    final rirDiff = loggedRir - targetRir;

    // Determine percentage adjustment based on RIR difference
    double adjustment;
    if (rirDiff <= -2) {
      // Much harder than expected (e.g., target RIR 2, actual RIR 0)
      adjustment = -0.15; // 15% drop
    } else if (rirDiff == -1) {
      // Slightly harder than expected
      adjustment = -0.075; // 7.5% drop
    } else if (rirDiff == 0) {
      // Perfect! Weight was right on target
      adjustment = 0;
    } else if (rirDiff == 1) {
      // Slightly easier than expected
      adjustment = 0.05; // 5% increase
    } else {
      // Much easier than expected (rirDiff >= 2)
      adjustment = 0.10; // 10% increase
    }

    // Calculate new weight
    final newWeight = currentWeight * (1 + adjustment);

    // Round to nearest equipment increment
    final roundedWeight = (newWeight / incrementKg).round() * incrementKg;

    // Ensure we don't go below the minimum increment
    return roundedWeight.clamp(incrementKg, 999.0);
  }

  /// Get adjustment info for UI display
  ///
  /// Returns a user-friendly message explaining the weight adjustment
  static ({double newWeight, String message, bool adjusted}) getWeightAdjustmentInfo({
    required double currentWeight,
    required int loggedRir,
    required int targetRir,
    double incrementKg = 2.5,
  }) {
    final newWeight = adjustWeightForRir(
      currentWeight: currentWeight,
      loggedRir: loggedRir,
      targetRir: targetRir,
      incrementKg: incrementKg,
    );

    final diff = newWeight - currentWeight;

    if (diff.abs() < 0.01) {
      return (
        newWeight: currentWeight,
        message: 'Perfect intensity! Keep the weight.',
        adjusted: false,
      );
    } else if (diff > 0) {
      return (
        newWeight: newWeight,
        message: 'Weight increased: ${currentWeight.toStringAsFixed(1)} → ${newWeight.toStringAsFixed(1)} kg',
        adjusted: true,
      );
    } else {
      return (
        newWeight: newWeight,
        message: 'Weight adjusted: ${currentWeight.toStringAsFixed(1)} → ${newWeight.toStringAsFixed(1)} kg',
        adjusted: true,
      );
    }
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

  // =========================================================================
  // REST TIME SUGGESTIONS
  // =========================================================================

  /// Get AI-powered rest time suggestion from the backend
  ///
  /// This method calls the Gemini-powered API endpoint for intelligent
  /// rest time suggestions that consider:
  /// - Exercise type (compound vs isolation)
  /// - Current RPE (Rate of Perceived Exertion)
  /// - Sets remaining (fatigue accumulation)
  /// - User's fitness goals
  ///
  /// Falls back to [generateRestSuggestion] if the API call fails.
  static Future<RestSuggestion?> getRestSuggestion({
    required Dio dio,
    required int rpe,
    required String exerciseType,
    String? exerciseName,
    required int setsRemaining,
    int setsCompleted = 0,
    required bool isCompound,
    List<String> userGoals = const [],
    String? muscleGroup,
  }) async {
    try {
      final response = await dio.post(
        '/workouts/rest-suggestion',
        data: {
          'rpe': rpe,
          'exercise_type': exerciseType,
          'exercise_name': exerciseName,
          'sets_remaining': setsRemaining,
          'sets_completed': setsCompleted,
          'is_compound': isCompound,
          'user_goals': userGoals,
          'muscle_group': muscleGroup,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return RestSuggestion.fromJson(response.data as Map<String, dynamic>);
      }

      // API returned non-200, fall back to rule-based
      return null;
    } catch (e) {
      // Log error and fall back to rule-based
      print('❌ [RestSuggestion] AI suggestion failed: $e');
      return null;
    }
  }

  /// Generate a local rule-based rest suggestion
  ///
  /// This is the fast, local fallback used when:
  /// - AI API is unavailable
  /// - Need instant response without network call
  ///
  /// Logic based on exercise science research:
  /// - Compound exercises need more rest than isolation
  /// - Higher RPE means more recovery needed
  /// - Later sets require more rest due to fatigue
  static RestSuggestion generateRestSuggestion({
    required int rpe,
    required bool isCompound,
    int setsCompleted = 0,
    int setsRemaining = 0,
    List<String> userGoals = const [],
  }) {
    // Base rest ranges (in seconds)
    // Compound exercises need longer rest for CNS recovery
    int baseMin;
    int baseMax;
    int quickOption;

    if (isCompound) {
      if (rpe >= 9) {
        // Heavy compound
        baseMin = 180;
        baseMax = 300;
        quickOption = 120;
      } else if (rpe >= 7) {
        // Moderate compound
        baseMin = 120;
        baseMax = 180;
        quickOption = 90;
      } else {
        // Light compound
        baseMin = 90;
        baseMax = 120;
        quickOption = 60;
      }
    } else {
      // Isolation exercises
      if (rpe >= 9) {
        baseMin = 90;
        baseMax = 120;
        quickOption = 60;
      } else if (rpe >= 7) {
        baseMin = 60;
        baseMax = 90;
        quickOption = 45;
      } else {
        baseMin = 45;
        baseMax = 60;
        quickOption = 30;
      }
    }

    // Calculate fatigue multiplier (later sets need more rest)
    double fatigueMult = 1.0;
    final setNumber = setsCompleted + 1;
    if (setNumber >= 6) {
      fatigueMult = 1.20;
    } else if (setNumber >= 5) {
      fatigueMult = 1.15;
    } else if (setNumber >= 4) {
      fatigueMult = 1.10;
    } else if (setNumber >= 3) {
      fatigueMult = 1.05;
    }

    // Calculate suggested rest (middle of range, adjusted for fatigue)
    var suggestedSeconds = ((baseMin + baseMax) / 2 * fatigueMult).round();

    // Round to nearest 15 seconds for cleaner numbers
    suggestedSeconds = ((suggestedSeconds / 15).round() * 15);

    // Adjust for user goals
    final goalsLower = userGoals.map((g) => g.toLowerCase()).toList();
    if (goalsLower.contains('strength')) {
      // Strength training benefits from longer rest
      suggestedSeconds = ((suggestedSeconds * 1.1) / 15).round() * 15;
    } else if (goalsLower.contains('endurance') ||
        goalsLower.contains('weight_loss')) {
      // Shorter rest maintains elevated heart rate
      suggestedSeconds = ((suggestedSeconds * 0.85) / 15).round() * 15;
    }

    // Determine rest category
    String restCategory;
    if (suggestedSeconds <= 60) {
      restCategory = 'short';
    } else if (suggestedSeconds <= 120) {
      restCategory = 'moderate';
    } else if (suggestedSeconds <= 180) {
      restCategory = 'long';
    } else {
      restCategory = 'extended';
    }

    // Generate reasoning
    final movementType = isCompound ? 'compound' : 'isolation';
    final intensity = rpe >= 9 ? 'high' : (rpe >= 7 ? 'moderate' : 'manageable');
    var reasoning =
        'Based on your $intensity effort (RPE $rpe) on this $movementType exercise';
    if (setNumber >= 4) {
      reasoning += ', and accounting for fatigue after ${setNumber - 1} sets';
    }
    reasoning +=
        '. This rest duration optimizes muscle recovery while maintaining workout momentum.';

    return RestSuggestion(
      suggestedSeconds: suggestedSeconds,
      reasoning: reasoning,
      quickOptionSeconds: quickOption,
      restCategory: restCategory,
      aiPowered: false,
    );
  }
}
