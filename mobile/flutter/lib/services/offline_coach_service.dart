import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat_message.dart';
import 'device_capability_service.dart';
import 'on_device_gemma_service.dart';
import 'workout_prompt_builder.dart';

/// Offline AI coach service that routes chat to local Gemma model.
///
/// Uses the loaded Gemma model to respond to user messages when offline.
/// Supports multimodal input (images) when Gemma 3n is loaded.
///
/// **Offline Mode is Coming Soon** — [isAvailable] always returns false
/// until Offline Mode launches.
class OfflineCoachService {
  final OnDeviceGemmaService _gemmaService;
  final WorkoutPromptBuilder _promptBuilder = WorkoutPromptBuilder();

  OfflineCoachService(this._gemmaService);

  /// Whether the offline coach is available (model loaded).
  /// Offline Mode is Coming Soon — always returns false.
  bool get isAvailable => false; // _gemmaService.isModelLoaded

  /// Whether the loaded model supports image input.
  bool get isMultimodal => _gemmaService.isMultimodal;

  /// The name of the currently loaded model.
  String get modelName {
    final type = _gemmaService.loadedModelType;
    if (type == null) return 'Unknown';
    return GemmaModelInfo.fromType(type).displayName;
  }

  /// Send a message to the offline AI coach.
  ///
  /// [userMessage] The user's text message.
  /// [conversationHistory] Previous messages for context.
  /// [userProfile] User's fitness profile for context injection.
  /// [imagePath] Optional image path for multimodal models.
  ///
  /// Returns a ChatMessage with the AI response.
  Future<ChatMessage> sendMessage({
    required String userMessage,
    List<Map<String, String>> conversationHistory = const [],
    Map<String, dynamic>? userProfile,
    String? currentWorkoutContext,
    String? imagePath,
  }) async {
    if (!isAvailable) {
      throw Exception('No AI model loaded. Please download a model first.');
    }

    // Build system prompt with user context
    final systemPrompt = _promptBuilder.buildChatSystemPrompt(
      fitnessLevel: userProfile?['fitness_level'] as String? ?? 'intermediate',
      goals: (userProfile?['goals'] as List?)?.join(', ') ?? 'general fitness',
      injuries: (userProfile?['active_injuries'] as List?)?.cast<String>() ?? [],
      currentWorkout: currentWorkoutContext,
    );

    // Build full conversation with system prompt
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
      {'role': 'user', 'content': userMessage},
    ];

    debugPrint('🤖 [OfflineCoach] Sending message to $modelName');
    debugPrint('🤖 [OfflineCoach] Conversation length: ${messages.length} messages');
    if (imagePath != null) {
      debugPrint('🤖 [OfflineCoach] With image: $imagePath');
    }

    try {
      final response = await _gemmaService.generateChat(
        messages,
        imagePath: imagePath,
      );

      debugPrint('✅ [OfflineCoach] Got response: ${response.length} chars');

      return ChatMessage(
        role: 'assistant',
        content: response.trim(),
        agentType: AgentType.coach,
        createdAt: DateTime.now().toIso8601String(),
        actionData: {
          'offline': true,
          'model': _gemmaService.loadedModelType?.name ?? 'unknown',
        },
      );
    } catch (e) {
      debugPrint('❌ [OfflineCoach] Error: $e');
      throw Exception('Offline AI failed to respond: $e');
    }
  }
}

// Provider
final offlineCoachServiceProvider = Provider<OfflineCoachService>((ref) {
  final gemmaService = ref.watch(onDeviceGemmaServiceProvider);
  return OfflineCoachService(gemmaService);
});
