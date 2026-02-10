import 'dart:convert';

import 'device_capability_service.dart';

/// Builds structured prompts for on-device Gemma models to generate workouts.
///
/// Two prompt formats are supported:
/// - Function calling format for FunctionGemma 270M
/// - Instruction format for Gemma 3 1B / Gemma 3n E2B / Gemma 3n E4B
class WorkoutPromptBuilder {
  /// Build a prompt for FunctionGemma 270M using function-calling format.
  ///
  /// FunctionGemma expects a tool/function definition followed by user input,
  /// and responds with a structured function call containing the workout JSON.
  String buildFunctionGemmaPrompt({
    required String splitType,
    required String fitnessLevel,
    required List<String> availableEquipment,
    required String goal,
    int durationMinutes = 45,
    List<String> avoidedExercises = const [],
    List<String> injuries = const [],
  }) {
    final equipmentStr = availableEquipment.isNotEmpty
        ? availableEquipment.join(', ')
        : 'bodyweight only';

    final avoidedStr = avoidedExercises.isNotEmpty
        ? '\nAvoid these exercises: ${avoidedExercises.join(', ')}'
        : '';

    final injuryStr = injuries.isNotEmpty
        ? '\nInjuries/limitations: ${injuries.join(', ')}'
        : '';

    return '''[AVAILABLE_TOOLS]
[{"type": "function", "function": {"name": "generate_workout", "description": "Generate a structured workout plan", "parameters": {"type": "object", "properties": {"name": {"type": "string"}, "type": {"type": "string"}, "difficulty": {"type": "string"}, "duration_minutes": {"type": "integer"}, "exercises": {"type": "array", "items": {"type": "object", "properties": {"name": {"type": "string"}, "sets": {"type": "integer"}, "reps": {"type": "integer"}, "rest_seconds": {"type": "integer"}, "weight": {"type": "number"}, "equipment": {"type": "string"}, "muscle_group": {"type": "string"}, "primary_muscle": {"type": "string"}, "notes": {"type": "string"}, "set_targets": {"type": "array", "items": {"type": "object", "properties": {"set_number": {"type": "integer"}, "set_type": {"type": "string"}, "target_reps": {"type": "integer"}, "target_rpe": {"type": "integer"}}}}}}}}}}]
[END_AVAILABLE_TOOLS]

Generate a $splitType workout for a $fitnessLevel level person.
Goal: $goal
Equipment: $equipmentStr
Duration: $durationMinutes minutes$avoidedStr$injuryStr

Create 5-8 exercises with 3-4 sets each. Include appropriate rest times (60-90s for compound, 45-60s for isolation). Use proper muscle group targeting for a $splitType split.''';
  }

  /// Build a prompt for Gemma 3 1B / Gemma 3n E2B / Gemma 3n E4B using instruction format.
  ///
  /// These models respond better to detailed instruction prompts with
  /// explicit JSON schema examples.
  String buildInstructionPrompt({
    required String splitType,
    required String fitnessLevel,
    required List<String> availableEquipment,
    required String goal,
    int durationMinutes = 45,
    List<String> avoidedExercises = const [],
    List<String> injuries = const [],
  }) {
    final equipmentStr = availableEquipment.isNotEmpty
        ? availableEquipment.join(', ')
        : 'bodyweight only';

    final avoidedStr = avoidedExercises.isNotEmpty
        ? 'Exercises to AVOID: ${avoidedExercises.join(', ')}\n'
        : '';

    final injuryStr = injuries.isNotEmpty
        ? 'Injuries/limitations to work around: ${injuries.join(', ')}\n'
        : '';

    return '''You are a certified personal trainer. Generate a workout plan as a JSON object.

USER PROFILE:
- Split type: $splitType
- Fitness level: $fitnessLevel
- Goal: $goal
- Available equipment: $equipmentStr
- Target duration: $durationMinutes minutes
$avoidedStr$injuryStr
REQUIREMENTS:
- Generate 5-8 exercises appropriate for a $splitType workout
- Each exercise should have 3-4 sets with specific rep targets
- Include rest periods: 90-120s for heavy compounds, 60-90s for accessories, 45-60s for isolation
- Vary set types where appropriate (warmup sets for first compound exercise, working sets, optional AMRAP final set)
- Choose exercises suitable for a $fitnessLevel fitness level
- All exercises must use available equipment: $equipmentStr

OUTPUT FORMAT - respond with ONLY this JSON structure, no other text:
{
  "name": "Workout Name (e.g., Upper Body Push)",
  "type": "$splitType",
  "difficulty": "$fitnessLevel",
  "duration_minutes": $durationMinutes,
  "exercises": [
    {
      "name": "Exercise Name",
      "sets": 4,
      "reps": 10,
      "rest_seconds": 90,
      "weight": 0,
      "equipment": "barbell",
      "muscle_group": "chest",
      "primary_muscle": "pectoralis major",
      "notes": "Brief form cue",
      "set_targets": [
        {"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_rpe": 5},
        {"set_number": 2, "set_type": "working", "target_reps": 10, "target_rpe": 7},
        {"set_number": 3, "set_type": "working", "target_reps": 10, "target_rpe": 8},
        {"set_number": 4, "set_type": "working", "target_reps": 8, "target_rpe": 9}
      ]
    }
  ]
}

Respond with ONLY the JSON object. No markdown, no explanation, no code blocks.''';
  }

  /// Build the appropriate prompt based on the model type.
  String buildPrompt({
    required GemmaModelType modelType,
    required String splitType,
    required String fitnessLevel,
    required List<String> availableEquipment,
    required String goal,
    int durationMinutes = 45,
    List<String> avoidedExercises = const [],
    List<String> injuries = const [],
  }) {
    switch (modelType) {
      case GemmaModelType.functionGemma270M:
        return buildFunctionGemmaPrompt(
          splitType: splitType,
          fitnessLevel: fitnessLevel,
          availableEquipment: availableEquipment,
          goal: goal,
          durationMinutes: durationMinutes,
          avoidedExercises: avoidedExercises,
          injuries: injuries,
        );
      case GemmaModelType.gemma3_1B:
      case GemmaModelType.gemma3n_E2B:
      case GemmaModelType.gemma3n_E4B:
        return buildInstructionPrompt(
          splitType: splitType,
          fitnessLevel: fitnessLevel,
          availableEquipment: availableEquipment,
          goal: goal,
          durationMinutes: durationMinutes,
          avoidedExercises: avoidedExercises,
          injuries: injuries,
        );
      case GemmaModelType.embeddingGemma300M:
        throw Exception('Embedding model cannot generate workouts');
    }
  }

  /// Build a system prompt for offline coach chat context.
  String buildChatSystemPrompt({
    required String fitnessLevel,
    required String goals,
    List<String> injuries = const [],
    String? currentWorkout,
  }) {
    return '''You are a knowledgeable fitness coach. You provide helpful, accurate fitness advice.

USER PROFILE:
- Fitness level: $fitnessLevel
- Goals: $goals
${injuries.isNotEmpty ? '- Injuries/limitations: ${injuries.join(', ')}' : ''}
${currentWorkout != null ? '\nCURRENT WORKOUT CONTEXT:\n$currentWorkout' : ''}

GUIDELINES:
- Give concise, practical fitness advice
- Be encouraging but honest
- If you don't know something, say so
- Focus on safety and proper form
- Do not prescribe specific medical treatments
- You cannot generate workouts, modify schedules, or log data in this offline mode''';
  }

  /// Extract JSON workout data from raw model output.
  ///
  /// Handles various output formats:
  /// - Pure JSON
  /// - JSON wrapped in markdown code blocks
  /// - FunctionGemma function call format
  /// - JSON with surrounding text
  Map<String, dynamic>? extractWorkoutJson(String modelOutput) {
    if (modelOutput.trim().isEmpty) return null;

    final cleaned = modelOutput.trim();

    // Try 1: FunctionGemma function call format
    // Output looks like: [TOOL_CALL] generate_workout({"name": ..., "exercises": [...]})
    final functionCallMatch = RegExp(
      r'generate_workout\s*\(\s*(\{[\s\S]*\})\s*\)',
    ).firstMatch(cleaned);
    if (functionCallMatch != null) {
      final result = _tryParseJson(functionCallMatch.group(1)!);
      if (result != null) return result;
    }

    // Try 2: JSON in markdown code block
    final codeBlockMatch = RegExp(
      r'```(?:json)?\s*\n?([\s\S]*?)\n?```',
    ).firstMatch(cleaned);
    if (codeBlockMatch != null) {
      final result = _tryParseJson(codeBlockMatch.group(1)!);
      if (result != null) return result;
    }

    // Try 3: Direct JSON object (find outermost braces)
    final jsonObjectMatch = RegExp(
      r'(\{[\s\S]*\})',
    ).firstMatch(cleaned);
    if (jsonObjectMatch != null) {
      final result = _tryParseJson(jsonObjectMatch.group(1)!);
      if (result != null) return result;
    }

    return null;
  }

  /// Attempt to parse a string as JSON, returning null on failure.
  Map<String, dynamic>? _tryParseJson(String input) {
    try {
      final trimmed = input.trim();
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        // Validate minimum structure - must have exercises or name
        if (decoded.containsKey('exercises') || decoded.containsKey('name')) {
          return decoded;
        }
      }
    } catch (_) {
      // Not valid JSON
    }
    return null;
  }
}
