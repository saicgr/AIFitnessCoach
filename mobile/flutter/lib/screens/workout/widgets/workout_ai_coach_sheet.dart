/// Workout AI Coach Sheet
///
/// Context-aware AI chat during workout that integrates with
/// existing chat system (shared history, AI settings, coach persona).
library;

import 'dart:ui';

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

/// Show AI coach sheet during workout
Future<void> showWorkoutAICoachSheet({
  required BuildContext context,
  required WidgetRef ref,
  required WorkoutExercise currentExercise,
  required int completedSets,
  required int totalSets,
  required double currentWeight,
  required bool useKg,
  required List<WorkoutExercise> remainingExercises,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (ctx) => WorkoutAICoachSheet(
      currentExercise: currentExercise,
      completedSets: completedSets,
      totalSets: totalSets,
      currentWeight: currentWeight,
      useKg: useKg,
      remainingExercises: remainingExercises,
    ),
  );
}

/// Quick prompt for workout context
class QuickPrompt {
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;

  const QuickPrompt({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

/// Workout AI coach sheet widget
class WorkoutAICoachSheet extends ConsumerStatefulWidget {
  final WorkoutExercise currentExercise;
  final int completedSets;
  final int totalSets;
  final double currentWeight;
  final bool useKg;
  final List<WorkoutExercise> remainingExercises;

  const WorkoutAICoachSheet({
    super.key,
    required this.currentExercise,
    required this.completedSets,
    required this.totalSets,
    required this.currentWeight,
    required this.useKg,
    required this.remainingExercises,
  });

  @override
  ConsumerState<WorkoutAICoachSheet> createState() => _WorkoutAICoachSheetState();
}

class _WorkoutAICoachSheetState extends ConsumerState<WorkoutAICoachSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isWaitingForResponse = false;
  int _lastMessageCount = 0;

  List<QuickPrompt> get _quickPrompts => [
    QuickPrompt(
      label: 'Form tips',
      prompt: 'What are the key form tips for ${widget.currentExercise.name}?',
      icon: Icons.sports_gymnastics,
      color: AppColors.cyan,
    ),
    QuickPrompt(
      label: 'Alternatives',
      prompt: 'What are some alternative exercises I can do instead of ${widget.currentExercise.name}?',
      icon: Icons.swap_horiz,
      color: AppColors.purple,
    ),
    QuickPrompt(
      label: 'Rest time?',
      prompt: 'How long should I rest between sets of ${widget.currentExercise.name}?',
      icon: Icons.timer_outlined,
      color: AppColors.orange,
    ),
    QuickPrompt(
      label: 'How many sets?',
      prompt: 'How many sets should I do of ${widget.currentExercise.name} for best results?',
      icon: Icons.format_list_numbered,
      color: AppColors.electricBlue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load chat history if not already loaded
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

    // Build workout context to prepend
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

    // Set waiting state for typing indicator
    setState(() {
      _isWaitingForResponse = true;
      _isTyping = false;
    });

    // Send the message with workout context
    ref.read(chatMessagesProvider.notifier).sendMessage(workoutContext);

    _messageController.clear();

    // Scroll to bottom after a short delay
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

  void _sendQuickPrompt(QuickPrompt prompt) {
    HapticFeedback.selectionClick();
    _sendMessage(prompt.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiSettings = ref.watch(aiSettingsProvider);
    final chatState = ref.watch(chatMessagesProvider);
    final coach = _getCoachPersona(aiSettings);
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

          // Header with coach info
          _buildHeader(isDark, coach),

          // Quick prompts
          _buildQuickPrompts(isDark),

          // Divider
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),

          // Chat messages
          Expanded(
            child: chatState.when(
              data: (messages) => _buildMessageList(messages, isDark, coach),
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
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.05, end: 0, duration: 200.ms);
  }

  Widget _buildHeader(bool isDark, CoachPersona coach) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Coach avatar
          CoachAvatar(
            coach: coach,
            size: 48,
            showBorder: true,
            showShadow: true,
          ),
          const SizedBox(width: 12),

          // Coach name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 13,
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
              Navigator.pop(context);
              context.push('/coach-selection?fromSettings=true');
            },
            tooltip: 'Change coach',
            icon: Icon(
              Icons.swap_horiz,
              color: isDark ? AppColors.textMuted : Colors.black54,
              size: 22,
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 6 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : Colors.black54,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Wrap(
            spacing: isCompact ? 6 : 8,
            runSpacing: isCompact ? 6 : 8,
            children: _quickPrompts.map((prompt) {
              return GestureDetector(
                onTap: () => _sendQuickPrompt(prompt),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: isCompact ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: prompt.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                    border: Border.all(
                      color: prompt.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(prompt.icon, size: isCompact ? 14 : 16, color: prompt.color),
                      SizedBox(width: isCompact ? 4 : 6),
                      Text(
                        prompt.label,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          color: prompt.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
    // Check if we got a new assistant message (response received)
    if (_isWaitingForResponse && messages.length > _lastMessageCount) {
      // Check if the newest message is from assistant
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

    // Update message count
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
              size: 48,
              color: isDark ? AppColors.textMuted : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask me anything about your workout!',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textMuted : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Show only last 20 messages for performance
    final recentMessages = messages.length > 20
        ? messages.sublist(messages.length - 20)
        : messages;

    // Add +1 for typing indicator if waiting
    final itemCount = recentMessages.length + (_isWaitingForResponse ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show typing indicator as last item
        if (_isWaitingForResponse && index == recentMessages.length) {
          return _buildTypingIndicator(isDark, coach);
        }

        final message = recentMessages[index];
        final isUser = message.role == 'user';

        return _buildMessageBubble(message, isUser, isDark, coach);
      },
    );
  }

  /// Build typing indicator with animated dots
  Widget _buildTypingIndicator(bool isDark, CoachPersona coach) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Coach avatar
          CoachAvatar(
            coach: coach,
            size: 32,
            showBorder: true,
            showShadow: false,
            enableTapToView: false, // Don't interrupt typing animation
          ),
          const SizedBox(width: 8),
          // Typing bubble with animated dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
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
    // Extract user question from workout context if present
    String displayContent = message.content;
    if (isUser && message.content.contains('[ACTIVE WORKOUT CONTEXT]')) {
      final lines = message.content.split('\n');
      final userQuestionIndex = lines.indexWhere((l) => l.startsWith('User question:'));
      if (userQuestionIndex != -1) {
        displayContent = lines[userQuestionIndex].replaceFirst('User question: ', '');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CoachAvatar(
              coach: coach,
              size: 32,
              showBorder: true,
              showShadow: false,
              enableTapToView: false, // Don't interrupt chat flow
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.electricBlue
                    : (isDark ? AppColors.elevated : Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                displayContent,
                style: TextStyle(
                  fontSize: 14,
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  fontSize: 15,
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
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _isTyping = value.isNotEmpty);
                },
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isTyping
                  ? () => _sendMessage(_messageController.text)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
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
                  size: 22,
                ),
              ),
            ),
          ],
        ),
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

    // Start animation after delay
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
