import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/e2ee_provider.dart';
import '../../data/providers/social_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/main_shell.dart';
import 'friend_profile_screen.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      // Initialize E2EE keys
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        ref.read(e2eeInitializedProvider(userId));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    Future.microtask(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final socialService = ref.read(socialServiceProvider);
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => FriendProfileScreen(
                  targetUserId: widget.otherUserId,
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.accent.withValues(alpha: 0.2),
                backgroundImage: widget.otherUserAvatar != null
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.otherUserName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: userId == null
                ? const Center(child: Text('Not logged in'))
                : _buildMessagesList(userId, isDark, colors),
          ),
          _buildInputBar(isDark, colors),
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

        // Messages typically come newest-first from API
        return Column(
          children: [
            if (decryptionFailures > 2)
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

                  return Column(
                    children: [
                      if (showTimestamp && createdAt != null)
                        _buildTimestamp(createdAt, isDark),
                      _buildMessageBubble(message, isMe, isDark, colors),
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
            if (isEncrypted)
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
                  onChanged: (_) => setState(() {}),
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
