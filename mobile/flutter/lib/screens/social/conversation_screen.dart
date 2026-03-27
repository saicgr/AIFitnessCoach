import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/conversation_realtime_provider.dart';
import '../../data/providers/e2ee_provider.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_loading.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/main_shell.dart';
import 'friend_profile_screen.dart';
import 'group_settings_screen.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatar;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.isGroup = false,
    this.groupName,
    this.groupAvatar,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(
        eventName: 'social_conversation_opened',
        properties: {'is_group': widget.isGroup},
      );
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        // Initialize E2EE keys only for DMs
        if (!widget.isGroup) {
          ref.read(e2eeInitializedProvider(userId));
        }
        // Join realtime channel for typing indicators
        final realtimeService = ref.read(conversationRealtimeServiceProvider);
        realtimeService.joinConversation(widget.conversationId);
        // Listen for typing events
        realtimeService.typingStream.listen((payload) {
          if (!mounted) return;
          final typingUserId = payload['user_id'] as String?;
          final typingUserName = payload['user_name'] as String?;
          final isTyping = payload['is_typing'] as bool? ?? false;
          if (typingUserId == null || typingUserId == userId) return;

          final currentList = ref.read(typingUsersProvider(widget.conversationId));
          final name = typingUserName ?? 'Someone';
          if (isTyping && !currentList.contains(name)) {
            ref.read(typingUsersProvider(widget.conversationId).notifier).state =
                [...currentList, name];
          } else if (!isTyping) {
            ref.read(typingUsersProvider(widget.conversationId).notifier).state =
                currentList.where((n) => n != name).toList();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    final realtimeService = ref.read(conversationRealtimeServiceProvider);
    realtimeService.leaveConversation();
    Future.microtask(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {});

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    const userName = 'User';
    if (userId == null) return;

    final realtimeService = ref.read(conversationRealtimeServiceProvider);

    // Debounce typing indicator - send true on keystroke, auto-clear after 2s
    _typingDebounceTimer?.cancel();
    if (text.trim().isNotEmpty) {
      realtimeService.sendTyping(widget.conversationId, userId, userName, true);
      _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
        realtimeService.sendTyping(widget.conversationId, userId, userName, false);
      });
    } else {
      realtimeService.sendTyping(widget.conversationId, userId, userName, false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    const userName = 'User';
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Send typing=false on message send
    _typingDebounceTimer?.cancel();
    final realtimeService = ref.read(conversationRealtimeServiceProvider);
    realtimeService.sendTyping(widget.conversationId, userId, userName, false);

    try {
      final socialService = ref.read(socialServiceProvider);

      // Skip E2EE for group conversations
      if (widget.isGroup) {
        await socialService.sendMessage(
          userId: userId,
          recipientId: widget.otherUserId,
          content: text,
          conversationId: widget.conversationId,
        );
      } else {
        final e2eeService = ref.read(e2eeServiceProvider);

        // Try to encrypt if recipient has a key
        String? encryptedContent;
        String? encryptionNonce;
        int? encryptionVersion;
        String? plainContent = text;

        final hasKey = await e2eeService.hasEncryptionKey(widget.otherUserId);
        if (hasKey) {
          final sharedSecret = await e2eeService.deriveSharedSecret(userId, widget.otherUserId);
          if (sharedSecret != null) {
            final encrypted = await e2eeService.encryptMessage(text, sharedSecret);
            if (encrypted != null) {
              encryptedContent = encrypted.ciphertext;
              encryptionNonce = encrypted.nonce;
              encryptionVersion = 1;
              plainContent = null;  // Don't send plaintext
            }
          }
        }

        await socialService.sendMessage(
          userId: userId,
          recipientId: widget.otherUserId,
          content: plainContent,
          conversationId: widget.conversationId,
          encryptedContent: encryptedContent,
          encryptionNonce: encryptionNonce,
          encryptionVersion: encryptionVersion,
        );
      }

      // Refresh messages
      ref.invalidate(conversationMessagesProvider(
        (userId: userId, conversationId: widget.conversationId, otherUserId: widget.otherUserId),
      ));
      // Also refresh conversation list for last message preview
      ref.invalidate(conversationsProvider(userId));
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (mounted) {
        // Restore the text so user can retry
        _messageController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final colors = ref.colors(context);

    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    final displayName = widget.isGroup
        ? (widget.groupName ?? 'Group Chat')
        : widget.otherUserName;
    final displayAvatar = widget.isGroup ? widget.groupAvatar : widget.otherUserAvatar;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: displayName,
        actions: [
          if (widget.isGroup)
            PillAppBarAction(
              icon: Icons.settings_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => GroupSettingsScreen(
                      conversationId: widget.conversationId,
                      groupName: widget.groupName ?? 'Group Chat',
                      groupAvatar: widget.groupAvatar,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: userId == null
                ? const Center(child: Text('Not logged in'))
                : _buildMessagesList(userId, isDark, colors),
          ),
          _buildTypingIndicator(),
          _buildInputBar(isDark, colors),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final typingUsers = ref.watch(typingUsersProvider(widget.conversationId));
    if (typingUsers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: _TypingDotsAnimation(),
                ),
                const SizedBox(width: 8),
                Text(
                  typingUsers.length == 1
                      ? '${typingUsers.first} is typing...'
                      : '${typingUsers.length} people typing...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(String userId, bool isDark, ThemeColors colors) {
    final messagesAsync = ref.watch(
      conversationMessagesProvider(
        (userId: userId, conversationId: widget.conversationId, otherUserId: widget.otherUserId),
      ),
    );

    return messagesAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (error, stack) {
        debugPrint('Error loading messages: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load messages',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(
                  conversationMessagesProvider(
                    (userId: userId, conversationId: widget.conversationId, otherUserId: widget.otherUserId),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (messages) {
        // Check for decryption failures
        final decryptionFailures = messages.where(
          (m) => (m['encryption_version'] as int? ?? 0) > 0 &&
                 m['decrypted_content'] == '[Unable to decrypt]'
        ).length;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 48,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send the first message!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        // Find the last sent message that has been read (for read receipts)
        // Compare message created_at against other participant's last_read_at
        int? lastReadSentIndex;
        final otherLastReadAt = messages.isNotEmpty
            ? messages.first['other_last_read_at'] as String?
            : null;
        if (otherLastReadAt != null) {
          try {
            final lastReadTime = DateTime.parse(otherLastReadAt);
            for (int i = 0; i < messages.length; i++) {
              final msg = messages[i];
              if (msg['sender_id'] == userId) {
                final msgTime = DateTime.tryParse(msg['created_at'] as String? ?? '');
                if (msgTime != null && !msgTime.isAfter(lastReadTime)) {
                  lastReadSentIndex = i;
                  break; // Messages are newest-first, so first match is the last read
                }
              }
            }
          } catch (_) {}
        }

        // Messages typically come newest-first from API
        return Column(
          children: [
            if (decryptionFailures > 2 && !widget.isGroup)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16,
                        color: isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some messages were encrypted on another device and cannot be read here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message['sender_id'] == userId;
                  final createdAt = message['created_at'] as String?;
                  final messageType = message['message_type'] as String?;

                  // Render system messages as centered grey text
                  if (messageType == 'system') {
                    return _buildSystemMessage(message, isDark);
                  }

                  // Show timestamp if gap > 5 minutes from next message
                  bool showTimestamp = false;
                  if (index < messages.length - 1) {
                    final nextMsg = messages[index + 1];
                    final nextTime = nextMsg['created_at'] as String?;
                    if (createdAt != null && nextTime != null) {
                      try {
                        final t1 = DateTime.parse(createdAt);
                        final t2 = DateTime.parse(nextTime);
                        if (t1.difference(t2).abs() > const Duration(minutes: 5)) {
                          showTimestamp = true;
                        }
                      } catch (_) {}
                    }
                  } else {
                    showTimestamp = true; // Always show timestamp for oldest message
                  }

                  final showReadReceipt = isMe && lastReadSentIndex == index;

                  return Column(
                    children: [
                      if (showTimestamp && createdAt != null)
                        _buildTimestamp(createdAt, isDark),
                      // For group messages: show sender name above received messages
                      if (widget.isGroup && !isMe)
                        _buildGroupSenderLabel(message, isDark),
                      _buildMessageBubble(message, isMe, isDark, ref.colors(context)),
                      if (showReadReceipt)
                        _buildReadReceipt(isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> message, bool isDark) {
    final content = message['content'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSenderLabel(Map<String, dynamic> message, bool isDark) {
    final senderName = message['sender_name'] as String? ?? 'Unknown';
    final senderAvatar = message['sender_avatar'] as String?;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.purple.withValues(alpha: 0.2),
            backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar) : null,
            child: senderAvatar == null
                ? Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadReceipt(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, right: 4),
        child: Text(
          'Read',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp(String timeString, bool isDark) {
    String formatted;
    try {
      final time = DateTime.parse(timeString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays == 0) {
        formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        formatted = 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        formatted = '${days[time.weekday - 1]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        formatted = '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      formatted = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        formatted,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, bool isDark, ThemeColors colors) {
    final encryptionVersion = message['encryption_version'] as int? ?? 0;
    final content = message['decrypted_content'] as String? ?? message['content'] as String? ?? '';
    final isEncrypted = encryptionVersion > 0;

    final bgColor = isMe
        ? colors.accent
        : (isDark ? AppColors.elevated : AppColorsLight.elevated);
    final textColor = isMe
        ? colors.accentContrast
        : (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary);
    final borderColor = isMe
        ? colors.accent
        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: borderColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.3,
              ),
            ),
            if (isEncrypted && !widget.isGroup)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 10,
                      color: isMe
                          ? colors.accentContrast.withValues(alpha: 0.6)
                          : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Encrypted',
                      style: TextStyle(
                        fontSize: 9,
                        color: isMe
                            ? colors.accentContrast.withValues(alpha: 0.6)
                            : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
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

  Widget _buildInputBar(bool isDark, ThemeColors colors) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevated,
          border: Border(
            top: BorderSide(color: cardBorder.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: _messageController.text.trim().isNotEmpty && !_isSending
                    ? _sendMessage
                    : null,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accent,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _messageController.text.trim().isNotEmpty
                            ? colors.accent
                            : textSecondary.withValues(alpha: 0.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dots for typing indicator
class _TypingDotsAnimation extends StatefulWidget {
  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final scale = t < 0.5 ? 1.0 + t * 0.6 : 1.0 + (1.0 - t) * 0.6;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4 + (scale - 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
