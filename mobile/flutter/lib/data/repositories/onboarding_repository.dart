import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Provider for onboarding repository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingRepository(apiClient);
});

/// Quick reply option from AI
class QuickReply {
  final String label;
  final dynamic value;
  final String? icon;

  QuickReply({
    required this.label,
    required this.value,
    this.icon,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      label: json['label'] as String,
      value: json['value'],
      icon: json['icon'] as String?,
    );
  }
}

/// Next question from AI
class NextQuestion {
  final String? question;
  final String type;
  final String? fieldTarget;
  final List<QuickReply>? quickReplies;
  final bool multiSelect;
  final String? component; // 'day_picker', etc.
  final bool complete;

  NextQuestion({
    this.question,
    required this.type,
    this.fieldTarget,
    this.quickReplies,
    this.multiSelect = false,
    this.component,
    this.complete = false,
  });

  factory NextQuestion.fromJson(Map<String, dynamic> json) {
    return NextQuestion(
      question: json['question'] as String?,
      type: json['type'] as String? ?? 'text',
      fieldTarget: json['field_target'] as String?,
      quickReplies: (json['quick_replies'] as List<dynamic>?)
          ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
          .toList(),
      multiSelect: json['multi_select'] as bool? ?? false,
      component: json['component'] as String?,
      complete: json['complete'] as bool? ?? false,
    );
  }
}

/// Response from parseOnboardingResponse API
class ParseOnboardingResult {
  final Map<String, dynamic> extractedData;
  final NextQuestion nextQuestion;
  final bool isComplete;
  final List<String> missingFields;

  ParseOnboardingResult({
    required this.extractedData,
    required this.nextQuestion,
    required this.isComplete,
    required this.missingFields,
  });

  factory ParseOnboardingResult.fromJson(Map<String, dynamic> json) {
    return ParseOnboardingResult(
      extractedData: (json['extracted_data'] as Map<String, dynamic>?) ?? {},
      nextQuestion:
          NextQuestion.fromJson(json['next_question'] as Map<String, dynamic>),
      isComplete: json['is_complete'] as bool? ?? false,
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Chat message for onboarding conversation
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<QuickReply>? quickReplies;
  final bool multiSelect;
  final String? component; // 'day_picker', 'basic_info_form', etc.
  final Map<String, dynamic>? extractedData;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.quickReplies,
    this.multiSelect = false,
    this.component,
    this.extractedData,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (extractedData != null) 'extracted_data': extractedData,
      };
}

/// Onboarding conversation state
class OnboardingConversationState {
  final List<ChatMessage> messages;
  final Map<String, dynamic> collectedData;
  final bool isActive;
  final bool isComplete;

  OnboardingConversationState({
    this.messages = const [],
    this.collectedData = const {},
    this.isActive = false,
    this.isComplete = false,
  });

  OnboardingConversationState copyWith({
    List<ChatMessage>? messages,
    Map<String, dynamic>? collectedData,
    bool? isActive,
    bool? isComplete,
  }) {
    return OnboardingConversationState(
      messages: messages ?? this.messages,
      collectedData: collectedData ?? this.collectedData,
      isActive: isActive ?? this.isActive,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Onboarding state notifier
class OnboardingStateNotifier extends StateNotifier<OnboardingConversationState> {
  OnboardingStateNotifier() : super(OnboardingConversationState());

  void setActive(bool active) {
    state = state.copyWith(isActive: active);
  }

  void addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void updateCollectedData(Map<String, dynamic> data) {
    state = state.copyWith(
      collectedData: {...state.collectedData, ...data},
    );
  }

  void setComplete(bool complete) {
    state = state.copyWith(isComplete: complete);
  }

  void reset() {
    state = OnboardingConversationState();
  }
}

/// Provider for onboarding conversation state
final onboardingStateProvider =
    StateNotifierProvider<OnboardingStateNotifier, OnboardingConversationState>(
        (ref) {
  return OnboardingStateNotifier();
});

/// Repository for onboarding API calls
class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository(this._apiClient);

  /// Parse user message and get next question from AI
  /// Uses LangGraph agent on backend
  Future<ParseOnboardingResult> parseOnboardingResponse({
    required String userId,
    required String message,
    required Map<String, dynamic> currentData,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      debugPrint('🤖 [Onboarding] Sending message to AI: $message');

      final response = await _apiClient.post(
        '${ApiConstants.onboarding}/parse-response',
        data: {
          'user_id': userId,
          'message': message,
          'current_data': currentData,
          if (conversationHistory != null)
            'conversation_history': conversationHistory,
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('⏱️ [Onboarding] Request timed out after 60 seconds');
          throw Exception('Request timed out. Please try again.');
        },
      );

      debugPrint('✅ [Onboarding] AI response received');
      debugPrint('📦 [Onboarding] Response data: ${response.data}');
      return ParseOnboardingResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Onboarding] Error parsing response: $e');
      rethrow;
    }
  }

  /// Save conversation to database
  Future<void> saveConversation({
    required String userId,
    required List<ChatMessage> messages,
  }) async {
    try {
      debugPrint('💾 [Onboarding] Saving conversation...');

      await _apiClient.post(
        '${ApiConstants.onboarding}/save-conversation',
        data: {
          'user_id': userId,
          'conversation': messages.map((m) => m.toJson()).toList(),
        },
      );

      debugPrint('✅ [Onboarding] Conversation saved');
    } catch (e) {
      debugPrint('❌ [Onboarding] Error saving conversation: $e');
      // Don't rethrow - saving is optional
    }
  }
}
