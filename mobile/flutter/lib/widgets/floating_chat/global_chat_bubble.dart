import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/animations/app_animations.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/chat_repository.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import '../coach_avatar.dart';

/// Global chat overlay that handles the modal chat UI
/// The AI button is now in main_shell.dart (fixed position beside nav bar)
class GlobalChatBubble extends ConsumerWidget {
  final Widget child;

  const GlobalChatBubble({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No longer showing overlay - AI button navigates to /chat screen
    // Just pass through the child widget
    return child;
  }
}

/// Chat modal widget
class _ChatModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _ChatModal({required this.onClose});

  @override
  ConsumerState<_ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends ConsumerState<_ChatModal> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() => _isLoading = true);

    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final nearBackgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Get coach persona from AI settings
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
    final coachName = coach.name;

    // Wrap in Material to provide the required ancestor for TextField and other Material widgets
    // Use ValueKey to avoid GlobalKey conflicts when theme changes
    return Material(
      key: const ValueKey('chat_modal_material'),
      type: MaterialType.transparency,
      child: Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CoachAvatar(
                  coach: coach,
                  size: 40,
                  showBorder: true,
                  showShadow: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coachName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _isLoading ? 'Typing...' : 'Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isLoading
                              ? (isDark ? AppColors.orange : AppColorsLight.orange)
                              : (isDark ? AppColors.success : AppColorsLight.success),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.swap_horiz, color: textMuted, size: 20),
                  onPressed: () {
                    widget.onClose();
                    context.push('/coach-selection?fromSettings=true');
                  },
                  tooltip: 'Change coach',
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted, size: 24),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          Divider(color: cardBorder, height: 1),

          // Messages
          Expanded(
            child: messagesState.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: isDark ? AppColors.error : AppColorsLight.error,
                        size: 40),
                    const SizedBox(height: 12),
                    Text('Error loading messages', style: TextStyle(color: textMuted)),
                    TextButton(
                      onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
            decoration: BoxDecoration(
              color: nearBackgroundColor,
              border: Border(
                top: BorderSide(color: cardBorder.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(fontSize: 15, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      hintStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [textMuted, textMuted]
                          : isDark
                              ? [AppColors.cyan, AppColors.purple]
                              : [AppColorsLight.cyan, AppColorsLight.purple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get coach persona
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    final suggestions = [
      'What should I eat before a workout?',
      'How can I improve my form?',
      'Create a quick workout for me',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CoachAvatar(
            coach: coach,
            size: 70,
            showBorder: true,
            borderWidth: 3,
            showShadow: true,
          ),
          const SizedBox(height: 20),
          Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about fitness',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                _textController.text = suggestion;
                _sendMessage();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: coach.primaryColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final userTextColor = isDark ? AppColors.pureBlack : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? cyan : elevated,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? userTextColor : textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
        .slideX(
          begin: isUser ? 0.05 : -0.05,
          end: 0,
          duration: AppAnimations.quick,
          curve: AppAnimations.decelerate,
        );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: _BouncingTypingDots(),
      ),
    );
  }
}

/// Bouncing typing dots animation - Messenger-like wave effect
class _BouncingTypingDots extends StatefulWidget {
  @override
  State<_BouncingTypingDots> createState() => _BouncingTypingDotsState();
}

class _BouncingTypingDotsState extends State<_BouncingTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.typingCycleDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Stagger each dot with a phase offset
            final offset = (index * 0.2);
            final progress = (_controller.value + offset) % 1.0;
            // Sine wave for smooth bounce: goes 0 -> 1 -> 0 in first half
            final bounce = math.sin(progress * math.pi * 2) * 0.5 + 0.5;
            final translateY = -AppAnimations.typingBounceHeight * bounce;

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.6 + bounce * 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
