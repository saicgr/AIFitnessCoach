import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/coach_persona.dart';
import '../../data/providers/coach_bubble_minimized_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';
import '../app_tour/app_tour_controller.dart';
import '../coach_avatar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'floating_chat_provider.dart';

import '../../l10n/generated/app_localizations.dart';
/// Floating AI Coach chat bubble widget with drag-to-dismiss support.
/// This is a self-contained widget that can be added to any Stack.
/// Uses floatingChatProvider for persistent state across navigation.
///
/// Press-and-hold the bubble (~500ms) to grab it (haptic confirms), then
/// drag to reposition. Drag into the bottom-center dismiss zone (trash
/// icon) to minimize to the side tab for today.
class FloatingChatBubble extends ConsumerStatefulWidget {
  const FloatingChatBubble({super.key});

  /// Height of the dismiss zone at the bottom of the screen.
  static const _dismissZoneHeight = 80.0;

  /// Whether the bubble's current bottom position is inside the dismiss zone.
  static bool _isInDismissZone(double bubbleBottom) => bubbleBottom <= 20;

  @override
  ConsumerState<FloatingChatBubble> createState() =>
      _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends ConsumerState<FloatingChatBubble> {
  // Position captured at long-press start. The long-press gesture reports
  // cumulative offset-from-origin (not per-frame delta), so we apply that
  // offset against the press-start origin to compute the new position.
  double _dragOriginRight = 0;
  double _dragOriginBottom = 0;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    // Per-day "minimized to side tab" override. When true, render the
    // glass side-tab form instead of the full draggable head — the user
    // dragged the head into the dismiss zone today and wants a tinier
    // footprint until midnight rollover.
    final isMinimizedToday = ref.watch(coachBubbleMinimizedProvider);
    if (isMinimizedToday) {
      return const _CoachSideTab();
    }

    final chatState = ref.watch(floatingChatProvider);
    final notifier = ref.read(floatingChatProvider.notifier);
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ── Dismiss zone (visible only while dragging) ──────────────
        if (chatState.isDragging)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: FloatingChatBubble._dismissZoneHeight + bottomPadding,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      (chatState.isOverDismissZone
                              ? Colors.red
                              : (isDark ? Colors.white : Colors.black))
                          .withValues(alpha: chatState.isOverDismissZone ? 0.25 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding + 16),
                    child: AnimatedScale(
                      scale: chatState.isOverDismissZone ? 1.3 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: chatState.isOverDismissZone
                              ? Colors.red
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.08)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: chatState.isOverDismissZone
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Draggable bubble ────────────────────────────────────────
        Positioned(
          right: chatState.bubbleRight,
          bottom: chatState.bubbleBottom + bottomPadding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Quick tap → open chat. (LongPress takes ~500ms, so a normal
            // tap never triggers the drag path below.)
            onTap: () {
              context.push('/chat');
            },
            // Press-and-hold-then-drag: drag is gated by a long-press so
            // a quick swipe across the bubble never accidentally pulls it
            // along. Mirrors the Material "draggable widget" idiom (you
            // see the same gate in chat-head implementations across iOS
            // and Android system UIs). Light haptic on press-start
            // confirms "grabbed" before any movement happens.
            onLongPressStart: (_) {
              HapticFeedback.selectionClick();
              // Capture the press-start position. `onLongPressMoveUpdate`
              // reports cumulative `offsetFromOrigin`, not per-frame delta,
              // so each subsequent update needs to apply the cumulative
              // offset against this captured origin.
              _dragOriginRight = chatState.bubbleRight;
              _dragOriginBottom = chatState.bubbleBottom;
              notifier.setDragging(true);
            },
            onLongPressMoveUpdate: (details) {
              // `right` decreases as finger moves right (bubbleRight is
              // distance FROM the right edge); `bottom` decreases as
              // finger moves down. Hence the inverted signs.
              final newRight =
                  (_dragOriginRight - details.offsetFromOrigin.dx)
                      .clamp(16.0, screenSize.width - 72);
              final newBottom =
                  (_dragOriginBottom - details.offsetFromOrigin.dy)
                      .clamp(0.0, screenSize.height - 200);
              notifier.updateBubblePosition(newRight, newBottom);
              notifier
                  .setOverDismissZone(FloatingChatBubble._isInDismissZone(newBottom));
            },
            onLongPressEnd: (_) {
              if (chatState.isOverDismissZone) {
                // Minimize for today — the head morphs into a glass
                // side-tab on the right edge until midnight local. User
                // keeps access (tap side-tab to bring head back) without
                // the full draggable footprint. Distinct from the
                // permanent settings opt-out (Settings → AI Coach toggle).
                HapticFeedback.heavyImpact();
                ref
                    .read(coachBubbleMinimizedProvider.notifier)
                    .minimize();
                // Reset position so the head reappears at a sane default
                // next time the user un-minimizes (next-day rollover or
                // tap on the side tab).
                notifier.updateBubblePosition(16, 100);
              } else {
                // Snap back if dragged too low but not into dismiss zone
                if (chatState.bubbleBottom < 100) {
                  notifier.updateBubblePosition(
                      chatState.bubbleRight, 100);
                }
              }
              notifier.setDragging(false);
            },
            child: AnimatedScale(
              scale: chatState.isDragging
                  ? (chatState.isOverDismissZone ? 0.7 : 1.1)
                  : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedOpacity(
                opacity: chatState.isOverDismissZone ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 150),
                // Glass-styled sparkle bubble. Always sparkle regardless
                // of whether a CoachPersona is selected — matches the
                // Coach hero card's eyebrow icon for brand consistency.
                // BackdropFilter + semi-transparent accent overlay makes
                // the head visually lighter on top of page content, so
                // it doesn't sit like a hard solid circle.
                child: _GlassSparkleHead(
                  key: AppTourKeys.aiChatKey,
                  isDragging: chatState.isDragging,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glass-styled circular sparkle head — the default visual for the
/// persistent floating coach bubble. Replaces the previous solid
/// purple/cyan gradient + CoachAvatar branches.
///
/// Effect: `BackdropFilter` blur 12 over whatever sits behind it, with a
/// 0.55-alpha accent overlay and a 1px white inner border. Reads as
/// "frosted glass with a sparkle inside" — visually lighter than a hard
/// solid circle, so the head doesn't compete as aggressively with page
/// content for attention.
///
/// Scaling/shadow nuances mirror the original behaviour: a stronger glow
/// while dragging so the user gets clear feedback that the gesture is
/// being recognised.
class _GlassSparkleHead extends StatelessWidget {
  final bool isDragging;
  const _GlassSparkleHead({super.key, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.accent.withValues(alpha: isDragging ? 0.75 : 0.55),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(
                    alpha: isDragging ? 0.45 : 0.28),
                blurRadius: isDragging ? 22 : 14,
                offset: const Offset(0, 4),
                spreadRadius: isDragging ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: c.accentContrast,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Glass-styled side tab. Renders on the right edge of the screen as a
/// compact rounded chip when the user has minimized the floating coach
/// head for the day via the drag-to-dismiss zone. Tap → restores the
/// full floating head; auto-restores on next-day midnight rollover via
/// [coachBubbleMinimizedProvider]'s per-day SharedPrefs key.
///
/// Position is fixed (vertically centered on the right edge) so the user
/// always knows where it is — different from the head, which is
/// draggable. Glass styling (BackdropFilter blur + accent overlay) makes
/// it visually lighter than the head so it competes less for attention.
class _CoachSideTab extends ConsumerWidget {
  const _CoachSideTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    return Positioned(
      right: 0,
      // Roughly centered vertically on the right edge — picked from the
      // ~30% mark above the nav so the user's thumb naturally finds it
      // without colliding with sticky in-page widgets that tend to sit
      // just above the nav.
      bottom: MediaQuery.sizeOf(context).height * 0.30,
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          ref.read(coachBubbleMinimizedProvider.notifier).expand();
        },
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 32,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.30), width: 1),
                  left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.30), width: 1),
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.30), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(-2, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: c.accentContrast,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Expandable chat modal
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

      // Award first-time chat bonus (+50 XP)
      ref.read(xpProvider.notifier).checkFirstChatBonus();
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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Get coach persona from AI settings
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
    final coachName = coach.name;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
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
                  size: 36,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _isLoading ? AppLocalizations.of(context).globalChatBubbleTyping : AppLocalizations.of(context).globalChatBubbleOnline,
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
                IconButton(
                  icon: Icon(Icons.swap_horiz, color: textMuted, size: 20),
                  onPressed: () {
                    widget.onClose();
                    context.push('/coach-selection?fromSettings=true');
                  },
                  tooltip: AppLocalizations.of(context).workoutAiCoachChangeCoach,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: widget.onClose,
                  tooltip: AppLocalizations.of(context).commonClose,
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
                    Text(AppLocalizations.of(context).globalChatBubbleErrorLoadingMessages, style: TextStyle(color: textMuted)),
                    TextButton(
                      onPressed: () => ref.read(chatMessagesProvider.notifier).loadHistory(),
                      child: Text(AppLocalizations.of(context).buttonRetry),
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
                top: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
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
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).globalChatBubbleAskYourAiCoach,
                      hintStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // Get coach persona
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

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
          CoachAvatar(
            coach: coach,
            size: 60,
            showBorder: true,
            borderWidth: 3,
            showShadow: true,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).globalChatBubbleHowCanIHelp,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).globalChatBubbleAskMeAnythingAbout,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
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
                      child: Text(
                        suggestion,
                        style: TextStyle(color: textPrimary),
                      ),
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final isError = message.role == 'error';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final userTextColor = isDark ? AppColors.pureBlack : Colors.white;

    if (isError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.error_outline, color: Colors.red, size: 16),
              ),
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.red[isDark ? 300 : 700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? userTextColor : textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
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
