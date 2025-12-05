import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  Map<String, dynamic> _collectedData = {};
  List<_QuickReply> _quickReplies = [];
  bool _isLoading = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startOnboarding();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startOnboarding() async {
    // Initial greeting
    await Future.delayed(const Duration(milliseconds: 500));
    _addAssistantMessage(
      "Hey! 👋 I'm your AI fitness coach. Let's set up your personalized workout plan.",
    );
    await Future.delayed(const Duration(milliseconds: 800));
    _addAssistantMessage(
      "First, what should I call you?",
      quickReplies: [],
    );
  }

  void _addAssistantMessage(String content, {List<_QuickReply>? quickReplies}) {
    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: content));
      if (quickReplies != null) {
        _quickReplies = quickReplies;
      }
    });
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: content));
      _quickReplies = [];
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    _addUserMessage(message);
    _textController.clear();

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Build conversation history
      final history = _messages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      final response = await apiClient.post(
        '${ApiConstants.onboarding}/parse-response',
        data: {
          'user_id': userId,
          'message': message,
          'current_data': _collectedData,
          'conversation_history': history,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Update collected data
        final extractedData = data['extracted_data'] as Map<String, dynamic>?;
        if (extractedData != null) {
          _collectedData.addAll(extractedData);
        }

        // Check if complete
        final isComplete = data['is_complete'] as bool? ?? false;
        if (isComplete) {
          _completeOnboarding();
          return;
        }

        // Show next question
        final nextQuestion = data['next_question'] as Map<String, dynamic>?;
        if (nextQuestion != null) {
          final question = nextQuestion['question'] as String?;
          final replies = nextQuestion['quick_replies'] as List?;

          List<_QuickReply> quickReplies = [];
          if (replies != null) {
            quickReplies = replies.map((r) {
              final map = r as Map<String, dynamic>;
              return _QuickReply(
                label: map['label'] as String,
                value: map['value'] as String,
              );
            }).toList();
          }

          await Future.delayed(const Duration(milliseconds: 500));
          _addAssistantMessage(question ?? '', quickReplies: quickReplies);
          setState(() => _quickReplies = quickReplies);
        }
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Error: $e');
      _addAssistantMessage(
        "Sorry, I had trouble understanding that. Could you try again?",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isComplete = true;
      _isLoading = true;
    });

    _addAssistantMessage(
      "Perfect! 🎉 I've got everything I need. Let me create your personalized workout plan...",
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Update user profile
      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          ..._collectedData,
          'onboarding_completed': true,
        },
      );

      // Refresh user data
      await ref.read(authStateProvider.notifier).refreshUser();

      await Future.delayed(const Duration(seconds: 2));

      _addAssistantMessage(
        "All set! Your workout plan is ready. Let's crush it! 💪",
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Complete error: $e');
      _addAssistantMessage(
        "There was an issue setting up your plan. Please try again.",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        title: const Text('Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: AppColors.glassSurface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index])
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1);
              },
            ),
          ),

          // Quick replies
          if (_quickReplies.isNotEmpty && !_isLoading)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final reply = _quickReplies[index];
                  return _QuickReplyChip(
                    label: reply.label,
                    onTap: () => _sendMessage(reply.value),
                  );
                },
              ),
            ),

          // Input field
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            isComplete: _isComplete,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    final requiredFields = [
      'name',
      'goals',
      'equipment',
      'days_per_week',
      'workout_duration',
      'fitness_level',
    ];
    final completed = requiredFields.where((f) => _collectedData.containsKey(f)).length;
    return completed / requiredFields.length;
  }
}

class _ChatMessage {
  final String role;
  final String content;

  _ChatMessage({required this.role, required this.content});
}

class _QuickReply {
  final String label;
  final String value;

  _QuickReply({required this.label, required this.value});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.cyan : AppColors.elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .fadeIn(delay: Duration(milliseconds: index * 200))
                .then()
                .fadeOut(delay: const Duration(milliseconds: 400));
          }),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isComplete;
  final Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isComplete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading && !isComplete,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isComplete ? 'Setup complete!' : 'Type your answer...',
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isLoading || isComplete
                ? null
                : () => onSend(controller.text),
            icon: Icon(
              Icons.send_rounded,
              color: isLoading || isComplete
                  ? AppColors.textMuted
                  : AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}
