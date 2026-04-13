part of 'chat_screen.dart';


/// Media send status for progressive loading states
enum _MediaSendStatus {
  idle,
  uploading,     // "Uploading image..." / "Uploading video..."
  analyzing,     // "Analyzing nutrition..." / "Checking exercise form..." / "Reading menu..."
  generating,    // "Generating response..." / "Thinking..."
}


// _EmptyChat replaced by EnhancedEmptyState widget
// _MessageBubble extracted to widgets/chat_message_bubble.dart (ChatMessageBubble)

// _MessageBubble extracted to widgets/chat_message_bubble.dart (ChatMessageBubble)

// ─────────────────────────────────────────────────────────────────
// Typing Indicator
// ─────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final String? statusText;
  final String? elapsed;

  const _TypingIndicator({this.statusText, this.elapsed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : Colors.grey.shade400,
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
            if (statusText != null && statusText!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                '$statusText${elapsed != null && elapsed!.isNotEmpty ? ' $elapsed' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Input Bar
// ─────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  final Future<void> Function(PickedMedia media) onSendWithMedia;
  final Future<void> Function(List<PickedMedia> mediaList) onSendWithMultiMedia;
  final Future<void> Function(File, int) onSendVoiceMessage;
  final bool isOffline;
  final String? modelName;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onSendWithMedia,
    required this.onSendWithMultiMedia,
    required this.onSendVoiceMessage,
    this.isOffline = false,
    this.modelName,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}


class _InputBarState extends State<_InputBar> {
  List<PickedMedia> _selectedMedia = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _pickMedia() async {
    debugPrint('🔍 [_InputBar] _pickMedia called');
    try {
      final result = await MediaPickerHelper.showMediaPickerSheet(context);
      debugPrint('🔍 [_InputBar] _pickMedia result: ${result?.media.length ?? 'null'}');
      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          // Append picked media, enforce max 5
          final combined = [..._selectedMedia, ...result.media];
          _selectedMedia = combined.take(5).toList();
        });
      }
    } on MediaValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [_InputBar] _pickMedia unexpected error: $e');
      debugPrint('❌ [_InputBar] Stack trace: $stackTrace');
    }
  }

  void _pickImageFromCamera() async {
    debugPrint('🔍 [_InputBar] _pickImageFromCamera called');
    try {
      final media = await MediaPickerHelper.pickImage(ImageSource.camera, context: context);
      if (media != null && mounted) {
        setState(() {
          final combined = [..._selectedMedia, media];
          _selectedMedia = combined.take(5).toList();
        });
      }
    } on MediaValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _pickVideo() {
    debugPrint('🔍 [_InputBar] _pickVideo called');
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Video',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _VideoPickerOption(
                icon: Icons.videocam_outlined,
                label: 'Record Video',
                subtitle: 'Use camera (max 60s)',
                color: const Color(0xFFF97316),
                onTap: () async {
                  Navigator.pop(ctx);
                  HapticService.selection();
                  try {
                    final media = await MediaPickerHelper.pickVideo(ImageSource.camera);
                    if (media != null && mounted) {
                      setState(() {
                        final combined = [..._selectedMedia, media];
                        _selectedMedia = combined.take(5).toList();
                      });
                    }
                  } on MediaValidationException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              _VideoPickerOption(
                icon: Icons.video_library_outlined,
                label: 'Choose Video',
                subtitle: 'From gallery (max 60s)',
                color: const Color(0xFFA855F7),
                onTap: () async {
                  Navigator.pop(ctx);
                  HapticService.selection();
                  try {
                    final media = await MediaPickerHelper.pickVideo(ImageSource.gallery);
                    if (media != null && mounted) {
                      setState(() {
                        final combined = [..._selectedMedia, media];
                        _selectedMedia = combined.take(5).toList();
                      });
                    }
                  } on MediaValidationException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    if (_selectedMedia.isNotEmpty) {
      final mediaList = List<PickedMedia>.from(_selectedMedia);
      setState(() => _selectedMedia = []);
      if (mediaList.length == 1) {
        widget.onSendWithMedia(mediaList.first);
      } else {
        widget.onSendWithMultiMedia(mediaList);
      }
    } else {
      widget.onSend();
    }
    // Dismiss keyboard after send
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : Colors.white,
        border: Border(
          top: BorderSide(color: colors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Media preview strip
          if (_selectedMedia.isNotEmpty)
            MediaPreviewStrip(
              mediaList: _selectedMedia,
              onRemoveAt: (index) => setState(() => _selectedMedia.removeAt(index)),
              onInsertAt: (index, media) => setState(() => _selectedMedia.insert(index, media)),
              onAddMore: _pickMedia,
            ),

          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isOffline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Offline AI${widget.modelName != null ? ' \u00b7 ${widget.modelName}' : ''}',
                          style: const TextStyle(fontSize: 11, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    // Camera button (quick image)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickImageFromCamera,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Video button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickVideo,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.videocam_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : const Color(0xFFF97316),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Media picker button (gallery + video)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.isLoading ? null : _pickMedia,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.attach_file_outlined,
                          size: 18,
                          color: widget.isLoading
                              ? colors.textMuted
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        enabled: true,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _selectedMedia.isNotEmpty
                              ? 'Add a message...'
                              : (widget.isLoading ? 'Type next message...' : 'Ask AI coach...'),
                          hintMaxLines: 1,
                          hintStyle: TextStyle(
                            color: colors.textMuted,
                            overflow: TextOverflow.ellipsis,
                          ),
                          filled: true,
                          fillColor: colors.glassSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Send or Voice button
                    if (_hasText || _selectedMedia.isNotEmpty || widget.isLoading)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isLoading
                                ? [colors.textMuted, colors.textMuted]
                                : [AppColors.cyan, AppColors.purple],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: widget.isLoading ? null : _handleSend,
                          icon: widget.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      )
                    else
                      VoiceRecorderButton(
                        onRecordingComplete: (audioFile, durationMs) {
                          widget.onSendVoiceMessage(audioFile, durationMs);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Video Picker Option (for _InputBar video button)
// ─────────────────────────────────────────────────────────────────

class _VideoPickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _VideoPickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}


// _GoToWorkoutButton extracted to widgets/chat_media_widgets.dart (GoToWorkoutButton)

// ─────────────────────────────────────────────────────────────────
// Escalate to Human Dialog
// ─────────────────────────────────────────────────────────────────

class _EscalateToHumanDialog extends ConsumerStatefulWidget {
  const _EscalateToHumanDialog();

  @override
  ConsumerState<_EscalateToHumanDialog> createState() => _EscalateToHumanDialogState();
}


class _EscalateToHumanDialogState extends ConsumerState<_EscalateToHumanDialog> {
  LiveChatCategory _selectedCategory = LiveChatCategory.general;
  bool _isLoading = false;

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.cyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Flexible(child: Text('Talk to Human Support')),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: LiveChatCategory.values.map((category) {
        return RadioListTile<LiveChatCategory>(
          contentPadding: EdgeInsets.zero,
          title: Text(
            category.displayName,
            style: const TextStyle(fontSize: 14),
          ),
          value: category,
          groupValue: _selectedCategory,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final availabilityAsync = ref.watch(liveChatAvailabilityProvider);
        return availabilityAsync.when(
          data: (availability) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: availability.isAvailable
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: availability.isAvailable
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    availability.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                    size: 20,
                    color: availability.isAvailable
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          availability.formattedWaitTime,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: availability.isAvailable
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                        if (availability.currentQueueSize > 0)
                          Text(
                            '${availability.currentQueueSize} people in queue',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cyan,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Checking availability...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8),
                Text(
                  'Wait time unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You will be connected with a real support agent who can help with your questions.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a category:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryList(),
          const SizedBox(height: 16),
          _buildAvailabilityInfo(),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);

    try {
      // Get last 10 messages from current AI chat as context
      final messagesState = ref.read(chatMessagesProvider);
      String aiContext = '';

      messagesState.whenData((messages) {
        final recentMessages = messages.length > 10
            ? messages.sublist(messages.length - 10)
            : messages;

        aiContext = recentMessages.map((m) {
          final role = m.role == 'user' ? 'User' : 'AI Coach';
          return '$role: ${m.content}';
        }).join('\n\n');
      });

      // Start live chat with escalation
      await ref.read(liveChatProvider.notifier).startChat(
            category: _selectedCategory.value,
            initialMessage:
                'Escalated from AI chat for ${_selectedCategory.displayName.toLowerCase()} help.',
            escalatedFromAi: true,
            aiContext: aiContext.isNotEmpty ? aiContext : null,
          );

      if (mounted) {
        Navigator.pop(context);
        HapticService.success();

        // Navigate to live chat screen
        context.push('/live-chat');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Connect'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }
}

