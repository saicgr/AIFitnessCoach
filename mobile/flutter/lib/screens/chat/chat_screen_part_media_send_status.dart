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
  // Elapsed seconds tick on a 1-Hz timer. Passing a ValueListenable instead of
  // a String lets only the elapsed `Text` rebuild each second — the rest of
  // the chat screen (message ListView, bubbles, scroll controller, input bar)
  // is no longer re-laid-out at 1 Hz.
  final ValueListenable<String>? elapsedListenable;

  const _TypingIndicator({this.statusText, this.elapsedListenable});

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
          border: Border.all(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(14).copyWith(
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
              elapsedListenable == null
                  ? Text(
                      statusText!,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? AppColors.textMuted : Colors.grey.shade500,
                      ),
                    )
                  : ValueListenableBuilder<String>(
                      valueListenable: elapsedListenable!,
                      builder: (context, elapsed, _) => Text(
                        elapsed.isEmpty ? statusText! : '$statusText $elapsed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMuted
                              : Colors.grey.shade500,
                        ),
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
    // Repaint the hairline field's border when focus changes (Signature
    // composer: focused = accent-tinted hairline, idle = plain hairline).
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
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

    // Single safe-area-aware bottom inset. On a notched device the home
    // indicator already provides spacing, so we DON'T also add a constant
    // pad on top of it (that double-counting was the oversized gap, issue 8).
    // When there is no safe-area inset (non-notched / keyboard open, where
    // viewInsets — not viewPadding — owns the gap) we add a small 8pt pad so
    // the input never sits flush against the screen edge.
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset = safeBottom > 0 ? safeBottom : 8.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureBlack : Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.hairline),
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
                // Signature composer — one hairline field holding the text
                // input with 📎 attach + 🎤 voice INLINE on the right, then the
                // accent send button outside it. Restructured to the v2
                // `nc-comp` composition; all media/voice/send wiring preserved.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // The hairline field: text + inline attach + inline voice.
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(
                            color: widget.focusNode.hasFocus
                                ? colors.accent.withValues(alpha: 0.9)
                                : colors.cardBorder,
                            width: widget.focusNode.hasFocus ? 1.4 : 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.only(left: 16, right: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                enabled: true,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLines: 4,
                                minLines: 1,
                                style: TextStyle(color: colors.textPrimary),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  hintText: _selectedMedia.isNotEmpty
                                      ? AppLocalizations.of(context)
                                          .inlineWorkoutChatAddAMessage
                                      : (widget.isLoading
                                          ? 'Type next message...'
                                          : 'Ask anything…'),
                                  hintMaxLines: 1,
                                  hintStyle: TextStyle(
                                    color: colors.textMuted,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                ),
                                onSubmitted: (_) => _handleSend(),
                              ),
                            ),
                            // Inline 📎 attach — opens the full media picker
                            // (camera photo / gallery / gallery video / record
                            // video), preserving every media path the old
                            // left-side button cluster reached.
                            _InlineComposerIcon(
                              icon: Icons.attach_file_rounded,
                              tooltip: AppLocalizations.of(context)
                                  .chatScreenPartAddVideo,
                              onTap: widget.isLoading ? null : _pickMedia,
                              color: widget.isLoading
                                  ? colors.textMuted
                                  : colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send (accent) / live-send spinner / Voice recorder —
                    // the action glyph sits OUTSIDE the hairline field.
                    if (_hasText || _selectedMedia.isNotEmpty || widget.isLoading)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: widget.isLoading
                              ? colors.surface
                              : colors.accent,
                          border: widget.isLoading
                              ? Border.all(color: colors.cardBorder)
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.isLoading ? null : _handleSend,
                          icon: widget.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.textMuted,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_upward_rounded,
                                  color: colors.accentContrast,
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
// Inline composer icon (📎 attach inside the hairline field)
// ─────────────────────────────────────────────────────────────────

/// A flat icon-only button that lives INSIDE the Signature composer's hairline
/// field (signature-v2 `nc-comp` inline glyphs). Real [Icons], no emoji-as-UI;
/// disabled when [onTap] is null (loading).
class _InlineComposerIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;

  const _InlineComposerIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20, color: color),
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
        Flexible(child: Text(AppLocalizations.of(context).chatScreenPartTalkToHumanSupport)),
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
          loading: () => Padding(
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
                  AppLocalizations.of(context).chatScreenPartCheckingAvailability,
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
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).chatScreenPartWaitTimeUnavailable,
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
          Text(
            AppLocalizations.of(context).chatScreenPartYouWillBeConnected,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).chatScreenPartSelectACategory,
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
        child: Text(AppLocalizations.of(context).buttonCancel),
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
            : Text(AppLocalizations.of(context).unifiedHomeWidgetsConnect),
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

