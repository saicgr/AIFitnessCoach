import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/workout.dart';
import 'device_capability_service.dart';
import 'workout_prompt_builder.dart';

/// On-device Gemma AI service for offline workout generation and chat.
///
/// Uses flutter_gemma v0.11+ API:
///   FlutterGemma.initialize() → installModel().fromFile() → getActiveModel() → createSession()
///
/// Supports Gemma 3 270M, Gemma 3 1B, Gemma 3n E2B, Gemma 3n E4B,
/// and EmbeddingGemma 300M.
///
/// NO FALLBACK - if generation fails, an error is thrown for the UI to handle.
class OnDeviceGemmaService {
  final WorkoutPromptBuilder _promptBuilder = WorkoutPromptBuilder();

  bool _isLoaded = false;
  GemmaModelType? _loadedModelType;
  InferenceModel? _activeModel;
  Timer? _autoUnloadTimer;

  static const Duration _autoUnloadDelay = Duration(minutes: 5);
  static const Duration _inferenceTimeout = Duration(seconds: 30);

  /// Whether a model is currently loaded in memory.
  bool get isModelLoaded => _isLoaded;

  /// The currently loaded model type, if any.
  GemmaModelType? get loadedModelType => _loadedModelType;

  /// Whether the currently loaded model supports image input.
  bool get isMultimodal {
    if (_loadedModelType == null) return false;
    return GemmaModelInfo.fromType(_loadedModelType!).isMultimodal;
  }

  /// Load a Gemma model into memory from the given file path.
  ///
  /// Throws if the model file cannot be loaded.
  Future<void> loadModel(String modelPath) async {
    debugPrint('🔍 [OnDeviceGemma] Loading model from: $modelPath');

    try {
      // Install from file path
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromFile(modelPath).install();

      // Get the active model with runtime params
      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: 8192,
        supportImage: isMultimodal,
      );

      _isLoaded = true;
      _resetAutoUnloadTimer();
      debugPrint('✅ [OnDeviceGemma] Model loaded successfully');
    } catch (e) {
      _isLoaded = false;
      _loadedModelType = null;
      _activeModel = null;
      debugPrint('❌ [OnDeviceGemma] Failed to load model: $e');
      throw Exception('Failed to load on-device AI model: $e');
    }
  }

  /// Load a specific model type by its local file path.
  Future<void> loadModelByType(GemmaModelType type, String modelPath) async {
    // If same model is already loaded, just reset the timer
    if (_isLoaded && _loadedModelType == type) {
      _resetAutoUnloadTimer();
      debugPrint('🔍 [OnDeviceGemma] Model ${type.name} already loaded, resetting timer');
      return;
    }

    // Unload current model if different
    if (_isLoaded) {
      await unloadModel();
    }

    _loadedModelType = type;
    await loadModel(modelPath);
  }

  /// Generate a response with an image input (multimodal models only).
  ///
  /// Throws if no model is loaded or current model is not multimodal.
  Future<String> generateWithImage(String prompt, String imagePath) async {
    if (!_isLoaded || _activeModel == null || _loadedModelType == null) {
      throw Exception('No model loaded');
    }
    final modelInfo = GemmaModelInfo.fromType(_loadedModelType!);
    if (!modelInfo.isMultimodal) {
      throw Exception('Current model does not support image input. Use Gemma 3n for multimodal.');
    }
    _resetAutoUnloadTimer();

    final session = await _activeModel!.createSession(
      temperature: 0.7,
      topK: 40,
      enableVisionModality: true,
    );

    try {
      // Read image file as bytes
      final imageBytes = await File(imagePath).readAsBytes();

      await session.addQueryChunk(Message.withImage(
        text: prompt,
        imageBytes: imageBytes,
        isUser: true,
      ));

      final response = await session.getResponse().timeout(_inferenceTimeout);
      return response;
    } finally {
      await session.close();
    }
  }

  /// Generate a chat-style response from a conversation history.
  ///
  /// [messages] is a list of maps with 'role' ('user' or 'assistant') and 'content' keys.
  /// Optionally pass [imagePath] for multimodal input on the latest message.
  Future<String> generateChat(List<Map<String, String>> messages, {String? imagePath}) async {
    if (!_isLoaded || _activeModel == null) throw Exception('No model loaded');
    _resetAutoUnloadTimer();

    final session = await _activeModel!.createSession(
      temperature: 0.7,
      topK: 40,
      enableVisionModality: imagePath != null && isMultimodal,
    );

    try {
      // Add conversation history as query chunks
      for (final msg in messages) {
        final isUser = msg['role'] == 'user';
        final text = msg['content'] ?? '';
        await session.addQueryChunk(Message.text(text: text, isUser: isUser));
      }

      // If there's an image for the last message, add it separately
      if (imagePath != null && isMultimodal) {
        final imageBytes = await File(imagePath).readAsBytes();
        await session.addQueryChunk(Message.withImage(
          text: '',
          imageBytes: imageBytes,
          isUser: true,
        ));
      }

      return await session.getResponse().timeout(const Duration(seconds: 60));
    } finally {
      await session.close();
    }
  }

  /// Generate a workout using the loaded on-device model.
  ///
  /// Returns a parsed [Workout] object.
  /// Throws on failure - NO FALLBACK behavior.
  Future<Workout> generateWorkout({
    required String splitType,
    required String fitnessLevel,
    required List<String> availableEquipment,
    required String goal,
    int durationMinutes = 45,
    List<String> avoidedExercises = const [],
    List<String> injuries = const [],
    required String userId,
    required String scheduledDate,
  }) async {
    if (!_isLoaded || _activeModel == null || _loadedModelType == null) {
      throw Exception('No model loaded. Please download and load a model first.');
    }

    _resetAutoUnloadTimer();

    final prompt = _promptBuilder.buildPrompt(
      modelType: _loadedModelType!,
      splitType: splitType,
      fitnessLevel: fitnessLevel,
      availableEquipment: availableEquipment,
      goal: goal,
      durationMinutes: durationMinutes,
      avoidedExercises: avoidedExercises,
      injuries: injuries,
    );

    debugPrint('🤖 [OnDeviceGemma] Generating workout with ${_loadedModelType!.name}...');
    debugPrint('🔍 [OnDeviceGemma] Prompt length: ${prompt.length} chars');

    // Run inference with timeout
    String rawOutput;
    try {
      final session = await _activeModel!.createSession(
        temperature: 0.7,
        topK: 40,
      );

      try {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        rawOutput = await session.getResponse().timeout(
          _inferenceTimeout,
          onTimeout: () =>
              throw TimeoutException('On-device AI generation timed out after ${_inferenceTimeout.inSeconds}s'),
        );
      } finally {
        await session.close();
      }
    } catch (e) {
      debugPrint('❌ [OnDeviceGemma] Inference failed: $e');
      throw Exception('On-device AI generation failed: $e');
    }

    debugPrint('🤖 [OnDeviceGemma] Raw output length: ${rawOutput.length} chars');

    // Parse the model output into a workout
    final workoutJson = _promptBuilder.extractWorkoutJson(rawOutput);
    if (workoutJson == null) {
      debugPrint('❌ [OnDeviceGemma] Failed to parse JSON from output');
      debugPrint('🔍 [OnDeviceGemma] Raw output: ${rawOutput.substring(0, rawOutput.length.clamp(0, 500))}');
      throw Exception(
        'On-device AI produced invalid output. The model could not generate a properly formatted workout.',
      );
    }

    // Convert parsed JSON to Workout model
    try {
      final workout = _buildWorkoutFromJson(
        workoutJson,
        userId: userId,
        scheduledDate: scheduledDate,
      );
      debugPrint('✅ [OnDeviceGemma] Workout generated: ${workout.name} with ${workout.exercises.length} exercises');
      return workout;
    } catch (e) {
      debugPrint('❌ [OnDeviceGemma] Failed to build Workout from JSON: $e');
      throw Exception('On-device AI output could not be converted to a workout: $e');
    }
  }

  /// Build a [Workout] object from the parsed JSON output.
  Workout _buildWorkoutFromJson(
    Map<String, dynamic> json, {
    required String userId,
    required String scheduledDate,
  }) {
    final exercises = <Map<String, dynamic>>[];
    final rawExercises = json['exercises'] as List<dynamic>?;

    if (rawExercises == null || rawExercises.isEmpty) {
      throw Exception('No exercises in generated workout');
    }

    for (int i = 0; i < rawExercises.length; i++) {
      final raw = rawExercises[i] as Map<String, dynamic>;

      // Build set_targets if present
      List<Map<String, dynamic>>? setTargets;
      if (raw['set_targets'] is List) {
        setTargets = (raw['set_targets'] as List).map((st) {
          final stMap = st as Map<String, dynamic>;
          return {
            'set_number': stMap['set_number'] ?? (i + 1),
            'set_type': stMap['set_type'] ?? 'working',
            'target_reps': stMap['target_reps'] ?? raw['reps'] ?? 10,
            'target_rpe': stMap['target_rpe'],
            'target_rir': stMap['target_rir'],
            'target_weight_kg': stMap['target_weight_kg'],
          };
        }).toList();
      }

      exercises.add({
        'name': raw['name'] ?? 'Exercise ${i + 1}',
        'sets': raw['sets'] ?? 3,
        'reps': raw['reps'] ?? 10,
        'rest_seconds': raw['rest_seconds'] ?? 60,
        'weight': (raw['weight'] as num?)?.toDouble() ?? 0.0,
        'equipment': raw['equipment'],
        'muscle_group': raw['muscle_group'],
        'primary_muscle': raw['primary_muscle'],
        'notes': raw['notes'],
        'is_completed': false,
        if (setTargets != null) 'set_targets': setTargets,
      });
    }

    final workoutId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    return Workout(
      id: workoutId,
      userId: userId,
      name: json['name'] as String? ?? 'On-Device Workout',
      type: json['type'] as String?,
      difficulty: json['difficulty'] as String?,
      scheduledDate: scheduledDate,
      isCompleted: false,
      exercisesJson: jsonEncode(exercises),
      durationMinutes: json['duration_minutes'] as int? ?? 45,
      generationMethod: 'on_device_gemma_${_loadedModelType!.name}',
      generationMetadata: {
        'model_type': _loadedModelType!.name,
        'generated_at': now,
        'on_device': true,
      },
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Unload the model from memory.
  Future<void> unloadModel() async {
    _autoUnloadTimer?.cancel();
    _autoUnloadTimer = null;

    if (_isLoaded) {
      debugPrint('🔍 [OnDeviceGemma] Unloading model: ${_loadedModelType?.name}');
      try {
        await _activeModel?.close();
      } catch (e) {
        debugPrint('⚠️ [OnDeviceGemma] Error closing model: $e');
      }
      _activeModel = null;
      _isLoaded = false;
      _loadedModelType = null;
      debugPrint('✅ [OnDeviceGemma] Model unloaded');
    }
  }

  /// Reset the auto-unload timer. Model will be unloaded after 5 minutes
  /// of inactivity to free memory.
  void _resetAutoUnloadTimer() {
    _autoUnloadTimer?.cancel();
    _autoUnloadTimer = Timer(_autoUnloadDelay, () {
      debugPrint('⚠️ [OnDeviceGemma] Auto-unloading model after ${_autoUnloadDelay.inMinutes}min inactivity');
      unloadModel();
    });
  }

  /// Dispose of the service and release resources.
  void dispose() {
    unloadModel();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Singleton on-device Gemma service provider.
final onDeviceGemmaServiceProvider = Provider<OnDeviceGemmaService>((ref) {
  final service = OnDeviceGemmaService();
  ref.onDispose(() => service.dispose());
  return service;
});
