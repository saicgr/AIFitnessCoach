/// Inline Workout Chat
///
/// Embeddable AI coach chat widget for use in foldable/split layouts.
/// Extracted from workout_ai_coach_sheet.dart - reuses the same
/// chatMessagesProvider and workout context injection logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../screens/ai_settings/ai_settings_screen.dart';
import '../../../widgets/coach_avatar.dart';

/// Quick prompt for workout context
class _QuickPrompt {
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;

  const _QuickPrompt({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

/// Inline workout chat widget - embeddable in any layout.
///
/// Provides the same AI coach chat as the bottom sheet version but
/// designed to be embedded inline (e.g. in a foldable right pane).
/// Supports collapse/expand toggle to minimize to just the quick-prompt bar.
class InlineWorkoutChat extends ConsumerStatefulWidget {
  final WorkoutExercise currentExercise;
  final int completedSets;
  final int totalSets;
  final double currentWeight;
  final bool useKg;
  final List<WorkoutExercise> remainingExercises;

  const InlineWorkoutChat({
    super.key,
    required this.currentExercise,
    required this.completedSets,
    required this.totalSets,
    required this.currentWeight,
    required this.useKg,
    required this.remainingExercises,
  });

  @override
  ConsumerState<InlineWorkoutChat> createState() => _InlineWorkoutChatState();
}

class _InlineWorkoutChatState extends ConsumerState<InlineWorkoutChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isWaitingForResponse = false;
  bool _isExpanded = true;
  int _lastMessageCount = 0;

  List<_QuickPrompt> get _quickPrompts => [
        _QuickPrompt(
          label: 'Form tips',
          prompt:
              'What are the key form tips for ${widget.currentExercise.name}?',
          icon: Icons.sports_gymnastics,
          color: AppColors.cyan,
        ),
        _QuickPrompt(
          label: 'Alternatives',
          prompt:
              'What are some alternative exercises I can do instead of ${widget.currentExercise.name}?',
          icon: Icons.swap_horiz,
          color: AppColors.purple,
        ),
        _QuickPrompt(
          label: 'Rest time?',
          prompt:
              'How long should I rest between sets of ${widget.currentExercise.name}?',
          icon: Icons.timer_outlined,
          color: AppColors.orange,
        ),
        _QuickPrompt(
          label: 'How many sets?',
          prompt:
              'How many sets should I do of ${widget.currentExercise.name} for best results?',
          icon: Icons.format_list_numbered,
          color: AppColors.electricBlue,
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    final workoutContext = '''
[ACTIVE WORKOUT CONTEXT]
Currently doing: ${widget.currentExercise.name}
Equipment: ${widget.currentExercise.equipment ?? 'bodyweight'}
Target muscle: ${widget.currentExercise.bodyPart ?? 'unknown'}
Set progress: ${widget.completedSets} of ${widget.totalSets} completed
Target reps: ${widget.currentExercise.reps ?? 'varies'}
Current weight: ${widget.useKg ? '${widget.currentWeight.toStringAsFixed(0)}kg' : '${widget.currentWeight.toStringAsFixed(0)}lbs'}
Exercises remaining: ${widget.remainingExercises.length}
---
User question: $message
''';

    setState(() {
      _isWaitingForResponse = true;
      _isTyping = false;
    });

    ref.read(chatMessagesProvider.notifier).sendMessage(workoutContext);

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickPrompt(_QuickPrompt prompt) {
    HapticFeedback.selectionClick();
    _sendMessage(prompt.prompt);
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiSettings = ref.watch(aiSettingsProvider);
    final chatState = ref.watch(chatMessagesProvider);
    final coach = _getCoachPersona(aiSettings);

    return Column(
      children: [
        // Header with coach info and collapse toggle
        _buildHeader(isDark, coach),

        // Quick prompts (always visible)
        _buildQuickPrompts(isDark),

        // Divider
        Divider(
          height: 1,
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),

        // Expandable chat area
        if (_isExpanded) ...[
          // Chat messages
          Expanded(
            child: chatState.when(
              data: (messages) =>
                  _buildMessageList(messages, isDark, coach),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.cyan,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load chat history',
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : Colors.black54,
                  ),
                ),
              ),
            ),
          ),

          // Input field
          _buildInputField(isDark),
        ],
      ],
    );
  }

  Widget _buildHeader(bool isDark, CoachPersona coach) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CoachAvatar(
            coach: coach,
            size: 36,
            showBorder: true,
            showShadow: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Swap coach button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/coach-selection?fromSettings=true');
            },
            tooltip: 'Change coach',
            icon: Icon(
              Icons.swap_horiz,
              color: isDark ? AppColors.textMuted : Colors.black54,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          ),

          // Collapse/expand toggle
          IconButton(
            onPressed: _toggleExpanded,
            tooltip: _isExpanded ? 'Collapse chat' : 'Expand chat',
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: isDark ? Colors.white : Colors.black,
                size: 22,
              ),
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _sendQuickPrompt(prompt),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: prompt.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: prompt.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(prompt.icon, size: 14, color: prompt.color),
                          const SizedBox(width: 4),
                          Text(
                            prompt.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: prompt.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<ChatMessage> messages,
    bool isDark,
    CoachPersona coach,
  ) {
    // Detect new assistant response
    if (_isWaitingForResponse && messages.length > _lastMessageCount) {
      if (messages.isNotEmpty && messages.last.role == 'assistant') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isWaitingForResponse = false;
              _lastMessageCount = messages.length;
            });
          }
        });
      }
    }

    if (messages.length != _lastMessageCount && !_isWaitingForResponse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _lastMessageCount = messages.length);
        }
      });
    }

    if (messages.isEmpty && !_isWaitingForResponse) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: isDark ? AppColors.textMuted : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me anything!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final recentMessages = messages.length > 20
        ? messages.sublist(messages.length - 20)
        : messages;

    final itemCount =
        recentMessages.length + (_isWaitingForResponse ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_isWaitingForResponse && index == recentMessages.length) {
          return _buildTypingIndicator(isDark, coach);
        }

        final message = recentMessages[index];
        final isUser = message.role == 'user';

        return _buildMessageBubble(message, isUser, isDark, coach);
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark, CoachPersona coach) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CoachAvatar(
            coach: coach,
            size: 28,
            showBorder: true,
            showShadow: false,
            enableTapToView: false,
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(delay: 0, color: coach.primaryColor),
                const SizedBox(width: 4),
                _AnimatedDot(delay: 150, color: coach.primaryColor),
                const SizedBox(width: 4),
                _AnimatedDot(delay: 300, color: coach.primaryColor),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isUser,
    bool isDark,
    CoachPersona coach,
  ) {
    String displayContent = message.content;
    if (isUser && message.content.contains('[ACTIVE WORKOUT CONTEXT]')) {
      final lines = message.content.split('\n');
      final userQuestionIndex =
          lines.indexWhere((l) => l.startsWith('User question:'));
      if (userQuestionIndex != -1) {
        displayContent =
            lines[userQuestionIndex].replaceFirst('User question: ', '');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CoachAvatar(
              coach: coach,
              size: 28,
              showBorder: true,
              showShadow: false,
              enableTapToView: false,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.electricBlue
                    : (isDark
                        ? AppColors.elevated
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: Text(
                displayContent,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about your workout...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textMuted : Colors.black38,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _isTyping = value.isNotEmpty);
              },
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isTyping
                ? () => _sendMessage(_messageController.text)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: _isTyping
                    ? const LinearGradient(
                        colors: [AppColors.cyan, AppColors.electricBlue],
                      )
                    : null,
                color: _isTyping
                    ? null
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isTyping
                    ? Colors.white
                    : (isDark ? AppColors.textMuted : Colors.black26),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  CoachPersona _getCoachPersona(AISettings aiSettings) {
    return CoachPersona.predefinedCoaches.firstWhere(
      (c) => c.id == aiSettings.coachPersonaId,
      orElse: () => CoachPersona.defaultCoach,
    );
  }
}

/// Animated dot for typing indicator
class _AnimatedDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _AnimatedDot({
    required this.delay,
    required this.color,
  });

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
