import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../screens/chat/chat_screen.dart';
import '../guest_upgrade_sheet.dart';
import '../main_shell.dart';
import 'floating_chat_provider.dart';

/// Hero tag for chat window animation
const String chatHeroTag = 'chat-window-hero';

/// Floating chat overlay - Facebook Messenger style
///
/// This widget is a pass-through that just returns the child.
/// The actual chat sheet is now shown from MainShell which has proper Navigator access.
/// This widget exists for backwards compatibility and may be removed.
class FloatingChatOverlay extends StatelessWidget {
  final Widget child;

  const FloatingChatOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Just pass through - the chat sheet is now handled by MainShell
    return child;
  }
}

/// Shows the chat bottom sheet using the given context.
/// This should be called from a widget that has Navigator access (like MainShell).
void showChatBottomSheet(BuildContext context, WidgetRef ref) {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the sheet to take full height
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (sheetContext) => _ChatBottomSheet(
      onClose: () {
        Navigator.of(sheetContext).pop();
      },
    ),
  ).whenComplete(() {
    // Collapse the state when sheet is dismissed
    ref.read(floatingChatProvider.notifier).collapse();
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

/// Shows the chat bottom sheet with no entry animation (for seamless minimize transition)
void showChatBottomSheetNoAnimation(BuildContext context, WidgetRef ref) {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    // Use a very fast animation to appear instantly
    transitionAnimationController: AnimationController(
      duration: const Duration(milliseconds: 1),
      vsync: Navigator.of(context),
    ),
    builder: (sheetContext) => _ChatBottomSheet(
      onClose: () {
        Navigator.of(sheetContext).pop();
      },
    ),
  ).whenComplete(() {
    ref.read(floatingChatProvider.notifier).collapse();
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

/// Chat bottom sheet content - uses proper Scaffold for IME handling
class _ChatBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _ChatBottomSheet({required this.onClose});

  @override
  ConsumerState<_ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends ConsumerState<_ChatBottomSheet> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(maxScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Check guest mode limits
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canChat = await ref.read(guestUsageLimitsProvider.notifier).useChatMessage();
      if (!canChat) {
        // Show upgrade prompt when limit reached
        if (mounted) {
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.chat);
        }
        return;
      }
    }

    HapticService.medium();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final nearBackgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Use Padding to handle keyboard - this is the Flutter-recommended way
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: screenHeight * 0.7,
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cyan, purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Coach',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          _isLoading ? 'Typing...' : 'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isLoading
                                ? (isDark ? AppColors.orange : AppColorsLight.orange)
                                : (isDark ? AppColors.success : AppColorsLight.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Maximize button - open full screen chat with animation
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      // Close the bottom sheet first
                      Navigator.of(context).pop();
                      // Navigate with custom animated route
                      Navigator.of(context).push(_createMaximizeRoute(context));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.open_in_full, color: textMuted, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      widget.onClose();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.close, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: cardBorder, height: 1),

            // Messages
            Expanded(
              child: messagesState.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: cyan),
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
                        onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return _buildEmptyState(context, cyan, purple, textPrimary, textMuted, cardBorder);
                  }

                  // Scroll to bottom when messages change
                  if (messages.length != _lastMessageCount) {
                    _lastMessageCount = messages.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom(animate: false);
                    });
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return _buildTypingIndicator(context);
                      }
                      return _buildMessageBubble(context, messages[index]);
                    },
                  );
                },
              ),
            ),

            // Input bar - directly in the sheet, no separate widget
            Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPadding + 12),
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
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask your AI coach...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 14),
                        filled: true,
                        fillColor: glassSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: cardBorder.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: cyan),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [textMuted, textMuted]
                            : [cyan, purple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildEmptyState(BuildContext context, Color cyan, Color purple, Color textPrimary, Color textMuted, Color cardBorder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final suggestions = [
      'What should I eat before a workout?',
      'How can I improve my form?',
      'Create a quick workout',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cyan, purple]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about fitness',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 24),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                HapticService.selection();
                _textController.text = suggestion;
                _sendMessage();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(suggestion, style: TextStyle(color: textPrimary)),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: textMuted),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final userTextColor = isDark ? AppColors.pureBlack : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? cyan : elevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? userTextColor : textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            // Show "Go to workout" button if AI generated a workout
            if (!isUser && message.hasGeneratedWorkout)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    // Close the chat drawer first, then navigate
                    Navigator.of(context).pop();
                    context.push('/workout/${message.workoutId}');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cyan, purple],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.workoutName != null ? 'Go to ${message.workoutName}' : 'Go to Workout',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _formatTime(message.timestamp ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 10,
                  color: isUser
                      ? userTextColor.withOpacity(0.6)
                      : textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[time.month - 1]} ${time.day}, $timeStr';
    }
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: elevated,
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
              decoration: BoxDecoration(
                color: textMuted,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(delay: Duration(milliseconds: index * 200))
                .then()
                .fadeOut(delay: const Duration(milliseconds: 400));
          }),
        ),
      ),
    );
  }
}

/// Creates a custom route for maximize animation (window expand effect)
Route _createMaximizeRoute(BuildContext context) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Curved animation for smooth feel
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Scale from bottom center (where the floating chat was)
      final scaleAnimation = Tween<double>(
        begin: 0.7,
        end: 1.0,
      ).animate(curvedAnimation);

      // Fade in
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ));

      // Slide up slightly
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Creates a custom route for minimize animation (window shrink effect)
/// Call this from ChatScreen when minimizing
Route createMinimizeRoute(BuildContext context, WidgetRef ref) {
  // This triggers showing the chat bottom sheet after animation
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionDuration: const Duration(milliseconds: 300),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return const SizedBox.shrink();
    },
  );
}
