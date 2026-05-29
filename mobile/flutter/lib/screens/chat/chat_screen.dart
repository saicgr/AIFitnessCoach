import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../../data/models/chat_message.dart';
import '../../data/providers/daily_coach_insight_provider.dart';
import '../../data/models/coach_persona.dart';
import 'widgets/suggested_reply_chips.dart';
import '../../data/models/live_chat_session.dart';
import '../../data/providers/live_chat_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/providers/offline_coach_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/coach_avatar.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';
import '../../widgets/medical_disclaimer_banner.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../exercises/import_exercise_screen.dart';
import '../workout/widgets/quick_workout_sheet.dart';
import '../../data/providers/equipment_match_pending_action_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/nutrition_repository.dart';
import 'widgets/food_analysis_inline_card.dart';
import '../../screens/nutrition/menu_analysis_sheet.dart';
import 'widgets/food_analysis_result_card.dart';
import 'widgets/form_check_result_card.dart';
import 'widgets/form_comparison_result_card.dart';
import 'widgets/fullscreen_image_viewer.dart';
import 'widgets/chat_search_overlay.dart';
import 'widgets/pinned_message_bar.dart';
import 'widgets/media_picker_helper.dart';
import 'widgets/media_preview_strip.dart';
import 'widgets/report_message_sheet.dart';
import 'widgets/chat_quick_pills.dart';
import 'widgets/chat_features_info_sheet.dart';
import 'widgets/enhanced_empty_state.dart';
import 'widgets/voice_message_widget.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_media_widgets.dart';
import '../../core/models/chat_quick_action.dart';
import '../../core/providers/usage_tracking_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/upgrade_prompt_sheet.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/providers/chat_locale_provider.dart';
import '../../core/providers/locale_provider.dart';

part 'chat_screen_part_media_send_status.dart';

part 'chat_screen_ui.dart';

part 'chat_screen_ext.dart';


/// ISO 639-1 code → native-script name for the chat system message.
/// Mirrors LOCALE_NATIVE_NAMES in backend/core/locale.py.
const _kChatLocaleNativeNames = <String, String>{
  'en': 'English', 'ar': 'العربية', 'bn': 'বাংলা', 'cs': 'Čeština',
  'de': 'Deutsch', 'es': 'Español', 'fi': 'Suomi', 'fr': 'Français',
  'ha': 'Hausa', 'hi': 'हिन्दी', 'id': 'Bahasa Indonesia',
  'it': 'Italiano', 'ja': '日本語', 'jv': 'Basa Jawa', 'kn': 'ಕನ್ನಡ',
  'ko': '한국어', 'ml': 'മലയാളം', 'mr': 'मराठी', 'ms': 'Bahasa Melayu',
  'ne': 'नेपाली', 'nl': 'Nederlands', 'or': 'ଓଡ଼ିଆ', 'pa': 'ਪੰਜਾਬੀ',
  'pl': 'Polski', 'pt': 'Português', 'ru': 'Русский', 'sv': 'Svenska',
  'sw': 'Kiswahili', 'ta': 'தமிழ்', 'te': 'తెలుగు', 'th': 'ภาษาไทย',
  'tl': 'Filipino', 'tr': 'Türkçe', 'ur': 'اردو', 'vi': 'Tiếng Việt',
  'zh': '中文',
};

/// Feature keys for premium gating
const _kFoodScanning = 'food_scanning';
const _kFormVideoAnalysis = 'form_video_analysis';
const _kAiChatMessages = 'ai_chat_messages';

/// Quick action IDs that require food_scanning gate
const _foodScanActions = {'scan_food', 'analyze_menu', 'calorie_check'};

/// Quick action IDs that require form_video_analysis gate
const _formVideoActions = {'check_form', 'compare_form'};

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  // ── Plan §1c.5 deep-link payload ─────────────────────────────────
  // When the user opens chat from a home card (coach hero / workout
  // card / pillar stat), the router forwards the source + insight_id
  // + card mode + workout id so chat can: (a) seed the same coach turn
  // the card showed, (b) render the suggested-reply chips matching the
  // card's mode, and (c) scope any chip-fired action_data to the right
  // workout.
  final String? source;
  final String? insightId;
  final String? cardMode;
  final String? workoutId;
  final String? contextLabel;

  /// Imports feature — when the share funnel lands the user in chat
  /// (intent=discuss / tip_save / nutrition_question, or "Just chat about
  /// this" escape hatch), these carry the original payload through so
  /// chat can preload the attachment list and prime the first turn.
  /// `initialAttachmentS3Keys` lists S3 keys already uploaded by the share
  /// pipeline (e.g. shared documents, PDFs).
  final List<String>? initialAttachmentS3Keys;

  /// Hint about what the user expects from the chat — surfaced as a
  /// pre-filled prompt the user can edit before sending. Values:
  ///   "analyze_form" · "explain_document" · "discuss"
  final String? initialIntent;

  /// Optional source URL — surfaced as context ("From: <url>") in the
  /// first turn when chat was reached via an X / Reddit / web share.
  final String? sourceUrl;

  const ChatScreen({
    super.key,
    this.initialMessage,
    this.source,
    this.insightId,
    this.cardMode,
    this.workoutId,
    this.contextLabel,
    this.initialAttachmentS3Keys,
    this.initialIntent,
    this.sourceUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  _MediaSendStatus _sendStatus = _MediaSendStatus.idle;
  DateTime? _sendStartTime;
  Timer? _elapsedTimer;
  // Drives the 1-Hz elapsed-seconds label inside the typing indicator without
  // calling setState on the entire chat screen each tick.
  final ValueNotifier<String> _elapsedNotifier = ValueNotifier<String>('');
  bool _initialMessageSent = false;
  bool _showScrollFAB = false;
  String? _highlightedMessageId;

  // C4 — mirrors whether the notifier currently has a streaming bubble
  // (live OR dropped). Only flips on null↔non-null transitions, so the
  // ListView rebuilds once per stream start/end — never per token. The
  // per-token repaints are isolated inside _StreamingBubble's own
  // ValueListenableBuilder.
  bool _streamingSlotVisible = false;
  // The notifier's streamingBubble listenable we attach a transition
  // listener to. Captured in initState's post-frame callback.
  ValueNotifier<StreamingBubbleState?>? _streamingBubbleRef;

  /// Listener on the notifier's streamingBubble — only triggers a screen
  /// rebuild when the bubble appears or disappears, never on content change.
  void _onStreamingTransition() {
    final present = _streamingBubbleRef?.value != null;
    if (present != _streamingSlotVisible && mounted) {
      setState(() => _streamingSlotVisible = present);
      if (present) _scrollToBottom();
    }
  }

  bool get _isLoading => _sendStatus != _MediaSendStatus.idle;

  // TODO(i18n): no context at _statusLabel getter — strings used in build() via _statusLabel
  String get _statusLabel {
    switch (_sendStatus) {
      case _MediaSendStatus.idle:
        return '';
      case _MediaSendStatus.uploading:
        return 'Uploading...';
      case _MediaSendStatus.analyzing:
        return 'Analyzing...';
      case _MediaSendStatus.generating:
        return 'Thinking...';
    }
  }

  String _computeElapsedLabel() {
    if (_sendStartTime == null) return '';
    final elapsed = DateTime.now().difference(_sendStartTime!).inSeconds;
    return '(${elapsed}s)';
  }

  void _startSendStatus(_MediaSendStatus status) {
    setState(() {
      _sendStatus = status;
      _sendStartTime = DateTime.now();
    });
    _elapsedNotifier.value = _computeElapsedLabel();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isLoading) return;
      // Only the elapsed label rebuilds — message ListView, bubbles, scroll
      // controller, and input bar stay still.
      _elapsedNotifier.value = _computeElapsedLabel();
    });
  }

  void _updateSendStatus(_MediaSendStatus status) {
    if (mounted) setState(() => _sendStatus = status);
  }

  void _stopSendStatus() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _elapsedNotifier.value = '';
    if (mounted) {
      setState(() {
        _sendStatus = _MediaSendStatus.idle;
        _sendStartTime = null;
      });
    }
  }

  /// Callback for _InputBar to send a voice message
  Future<void> _sendVoiceMessage(File audioFile, int durationMs) async {
    _startSendStatus(_MediaSendStatus.generating);
    try {
      await ref.read(chatMessagesProvider.notifier).sendVoiceMessage(audioFile, durationMs);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatScreenFailedToSendVoice(e.toString())), backgroundColor: AppColors.error),
        );
      }
    } finally {
      _stopSendStatus();
    }
  }

  @override
  void initState() {
    super.initState();
    // C3 — observe app lifecycle so a chat backgrounded mid-send re-syncs
    // its history on resume (handled in didChangeAppLifecycleState).
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showScrollFAB) setState(() => _showScrollFAB = show);

      // Load older messages when scrolling near the top (max extent in reversed list)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(chatMessagesProvider.notifier).loadOlderMessages();
      }
    });
    // Load chat history on screen load. Do NOT await on the no-initial-message
    // path — the chat scaffold paints immediately with cached/skeleton state
    // and history hydrates in the background. The initialMessage path still
    // awaits to avoid a race where loadHistory's server fetch overwrites
    // sendMessage state.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Attach the streaming-bubble transition listener (C4). Done here (not
      // in the field initializer) because the provider must be readable.
      if (mounted) {
        _streamingBubbleRef =
            ref.read(chatMessagesProvider.notifier).streamingBubble;
        _streamingBubbleRef!.addListener(_onStreamingTransition);
        // Sync initial state in case a stream was already in flight.
        _onStreamingTransition();
      }
      if (widget.initialMessage != null &&
          widget.initialMessage!.isNotEmpty &&
          !_initialMessageSent) {
        _initialMessageSent = true;
        await ref.read(chatMessagesProvider.notifier).loadHistory();
        if (mounted) {
          _textController.text = widget.initialMessage!;
          _sendMessage();
        }
      } else {
        // Fire-and-forget so first paint is not blocked on a network round-trip.
        unawaited(ref.read(chatMessagesProvider.notifier).loadHistory());
      }
      // Plan §1c.5 — seed the same coach turn the card showed when chat
      // was opened with ?insight_id=...&source=... Done AFTER loadHistory
      // kicks off so the synthetic turn appends to whatever the server
      // already has (the seeded turn lives in local state until the user
      // sends a reply that persists it).
      if (widget.insightId != null && widget.insightId!.isNotEmpty) {
        _seedInsightCoachTurn();
      }
    });
  }

  /// Build the chip strip rendered below a seeded coach turn. Maps the
  /// home card's `mode` (from the deep link) to the §1c.5 chip set, then
  /// wires each chip's tap to either send a user turn, fire a workout-card
  /// action, or deep-link a literal route. The strip is built once per
  /// render but the chips list itself is `const`-shaped and cheap.
  Widget _buildSuggestedChipsStrip() {
    // Compose the action payload once — workout_id is the most useful
    // scope for any chip-fired action. Other chips read what they need.
    final payload = <String, dynamic>{
      if (widget.workoutId != null && widget.workoutId!.isNotEmpty)
        'workout_id': widget.workoutId,
      if (widget.insightId != null) 'insight_id': widget.insightId,
      if (widget.source != null) 'source_surface': widget.source,
    };
    // Mode resolution: explicit cardMode wins; coach_hero falls back to a
    // morning/evening flavour based on current hour so the brief surfaces
    // its action chips even when only the source was passed.
    String? mode = widget.cardMode;
    if (mode == null && widget.source == 'coach_hero') {
      final h = DateTime.now().hour;
      if (h >= 5 && h <= 10) {
        mode = 'morning_brief';
      } else if (h >= 20 && h <= 21) {
        mode = 'evening_recap';
      }
    }
    final chips = chipsForWorkoutMode(mode, extraPayload: payload);
    return SuggestedReplyChips(
      chips: chips,
      onMessageTap: (label) {
        _textController.text = label;
        _sendMessage();
      },
      onActionTap: (kind, p) {
        // Fire-and-forget; the notifier appends its own confirmation turn.
        unawaited(
          ref.read(chatMessagesProvider.notifier)
              .dispatchWorkoutCardAction(kind, p),
        );
      },
      onRouteTap: (route) {
        try {
          context.push(route);
        } catch (_) {
          // Bad route is dev-time noise; surface a snack so QA notices.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.chatScreenRouteNotRegistered(route))),
            );
          }
        }
      },
    );
  }

  /// Insert ONE local coach turn keyed by [widget.insightId] at the
  /// bottom of today's chat (in chronological order — newest at bottom).
  /// Dedupe: if any existing message in state already carries this
  /// insightId in `intent`, skip. We piggy-back on `intent` because
  /// `ChatMessage` doesn't yet expose a dedicated insight_id field —
  /// the backend migration 2098 added the columns but the client model
  /// still ships them inside the existing intent slot until the next
  /// codegen-safe model bump.
  void _seedInsightCoachTurn() {
    try {
      final insight = ref.read(dailyCoachInsightProvider).valueOrNull;
      if (insight == null) return;
      final notifier = ref.read(chatMessagesProvider.notifier);
      final existing = ref.read(chatMessagesProvider).valueOrNull ?? [];
      final marker = 'insight:${widget.insightId}';
      final alreadySeeded = existing.any((m) => m.intent == marker);
      if (alreadySeeded) return;
      final headline = insight.headline.trim();
      final body = insight.body.trim();
      final content = [headline, body].where((s) => s.isNotEmpty).join('\n\n');
      if (content.isEmpty) return;
      notifier.appendSeededCoachTurn(
        content: content,
        intent: marker,
        sourceSurface: widget.source,
      );
    } catch (e) {
      debugPrint('🤖 [Chat] seedInsightCoachTurn failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamingBubbleRef?.removeListener(_onStreamingTransition);
    _elapsedTimer?.cancel();
    _elapsedNotifier.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // C3 — when the app returns to the foreground, force-refresh chat history.
    // A chat backgrounded mid-send (e.g. user switched apps while the AI was
    // streaming) could otherwise sit on a stale snapshot: the streamed reply
    // may have completed server-side without the client committing it.
    // force: true bypasses the "already have messages" short-circuit.
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(chatMessagesProvider.notifier).loadHistory(force: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(String messageId) {
    final messages = ref.read(chatMessagesProvider).valueOrNull ?? [];
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0 && _scrollController.hasClients) {
      final reversedIndex = messages.length - 1 - idx;
      final estimatedOffset = reversedIndex * 80.0;
      _scrollController.animateTo(
        estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      setState(() => _highlightedMessageId = messageId);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
    }
  }

  /// Minimize - shrink back to floating chat overlay with seamless animation
  void _minimizeToFloatingChat() {
    HapticService.light();
    // Capture the navigator + provider container BEFORE popping. Once the
    // widget unmounts, our `ref` becomes invalid (Riverpod throws "Cannot use
    // ref after the widget was disposed" if accessed). The container survives
    // the pop because it's owned by the ProviderScope above us, so we can
    // safely use it from the delayed callback.
    final navigator = Navigator.of(context);
    final rootContext = navigator.context;
    final container = ProviderScope.containerOf(context);

    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (rootContext.mounted) {
          showChatBottomSheetWithContainer(rootContext, container);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesState = ref.watch(chatMessagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for AI Coach chat-language changes and insert a WhatsApp-style
    // system message into the chat history when the user switches languages.
    // Uses ref.listen so it only fires on CHANGES (not on the initial build).
    ref.listen<ChatLocaleState>(chatLocaleProvider, (previous, next) {
      if (!mounted) return;
      final notifier = ref.read(chatMessagesProvider.notifier);
      final nextCode = next.locale?.languageCode;
      final prevCode = previous?.locale?.languageCode;
      if (nextCode == prevCode) return; // no actual change

      if (nextCode == null) {
        // User cleared the chat-language override — back to app language.
        notifier.addSystemNotification(l10n.chatLanguageResetSystem);
      } else {
        final nativeName = _kChatLocaleNativeNames[nextCode] ?? nextCode;
        notifier.addSystemNotification(
          l10n.chatLanguageChangedSystem(nativeName),
        );
      }
    });
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final offlineChatState = ref.watch(offlineChatStateProvider);

    // Get coach persona from AI settings.
    //
    // Important: while the notifier is still hydrating (cold start, no
    // SharedPreferences snapshot, API call in flight) we DO NOT fall back
    // to `CoachPersona.defaultCoach` — that's Coach Mike, and users with
    // a different persona saw Mike flash in the header for ~1s before the
    // real coach loaded. Per "no silent fallbacks", we render a neutral
    // "Loading coach…" header instead, then swap to the real persona once
    // hydration completes (either from cache or API).
    final aiSettings = ref.watch(aiSettingsProvider);
    final resolvedCoach = CoachPersona.findById(aiSettings.coachPersonaId);
    final showLoadingCoach = !aiSettings.isHydrated && resolvedCoach == null;
    final coach = resolvedCoach ?? CoachPersona.defaultCoach;
    final coachName = showLoadingCoach ? 'Loading coach…' : coach.name;

    final topBarColor = isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated;
    final topBarBorder = isDark
        ? null
        : Border.all(color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder).withValues(alpha: 0.3));
    final topBarShadow = BoxShadow(
      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
    final statusColor = _isLoading
        ? AppColors.orange
        : offlineChatState.isAvailable
            ? Colors.amber
            : AppColors.success;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main chat content — padded below the top bar
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 60),
          // Pinned message bar
          if (messagesState.valueOrNull != null)
            Builder(builder: (context) {
              final pinnedMsg = messagesState.valueOrNull!
                  .cast<ChatMessage?>()
                  .firstWhere((m) => m!.isPinned, orElse: () => null);
              if (pinnedMsg == null) return const SizedBox.shrink();
              return PinnedMessageBar(
                message: pinnedMsg,
                onTap: () => _scrollToMessage(pinnedMsg.id ?? ''),
                onUnpin: () => ref.read(chatMessagesProvider.notifier).togglePin(pinnedMsg.id!),
              );
            }),
          // Messages
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: messagesState.when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(color: AppColors.cyan),
                ),
                error: (e, _) {
                  // Collapse noisy transport errors (DioException [connection
                  // timeout / connection error / receive timeout]) into a
                  // single user-readable line. Differentiate timeout (coach
                  // is still working, server reachable) from true connection
                  // failure so the user doesn't reflexively check Wi-Fi when
                  // the LangGraph multi-agent run is just slow.
                  final errStr = e.toString();
                  final isReceiveTimeout = errStr.contains('receiveTimeout') ||
                      errStr.contains('receive timeout');
                  final isConnectionError = errStr.contains('SocketException') ||
                      errStr.contains('connectionError') ||
                      errStr.contains('Failed host lookup');
                  final isOtherTransport = errStr.contains('DioException') ||
                      errStr.contains('connection') ||
                      errStr.contains('timeout');
                  final headline = isReceiveTimeout
                      ? l10n.chatScreenCoachIsThinkingLonger
                      : (isConnectionError
                          ? l10n.chatScreenCantReachCoach
                          : (isOtherTransport
                              ? l10n.chatScreenCouldntReachCoach
                              : l10n.chatScreenSomethingWentWrongLoading));
                  return Center(
                    key: const ValueKey('error'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            // Subtitle tracks the headline so a slow
                            // backend reads as "still working" rather than
                            // suggesting the user's network is down.
                            errStr.contains('receiveTimeout') ||
                                    errStr.contains('receive timeout')
                                ? l10n.chatScreenMultiAgentHangTight
                                : l10n.chatScreenCheckConnection,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              HapticService.medium();
                              ref.read(chatMessagesProvider.notifier).loadHistory();
                            },
                            child: Text(l10n.buttonRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (messages) {
                  if (messages.isEmpty) {
                    return EnhancedEmptyState(
                      key: const ValueKey('empty'),
                      coach: coach,
                      onSuggestionTap: (suggestion) {
                        _textController.text = suggestion;
                        _sendMessage();
                      },
                    );
                  }

                  final hasMore = ref.read(chatMessagesProvider.notifier).hasMoreMessages;
                  // The newest slot (index 0) exists while a send is loading
                  // OR while a streaming bubble is present (a dropped reply
                  // outlives the loading state — the partial text must stay
                  // visible until the user retries, C2).
                  final hasNewestSlot = _isLoading || _streamingSlotVisible;
                  final extraItems = (hasNewestSlot ? 1 : 0) + (hasMore ? 1 : 0);

                  return ListView.builder(
                    key: const ValueKey('content'),
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    // Bubbles vary in height so a hard `itemExtent` would clip,
                    // but giving the framework a representative item lets it
                    // skip the per-item measure pass on initial scroll.
                    cacheExtent: 800,
                    itemCount: messages.length + extraItems,
                    itemBuilder: (context, index) {
                      // With reverse: true, index 0 = bottom (newest).
                      // The newest item (index 0) is either the live
                      // token-by-token streaming bubble (C4) or, before the
                      // first token arrives, the typing indicator. Both share
                      // this single slot so `extraItems` math is unchanged.
                      if (index == 0 && hasNewestSlot) {
                        final notifier =
                            ref.read(chatMessagesProvider.notifier);
                        // ValueListenableBuilder rebuilds ONLY this slot when
                        // streamingBubble flips between null and a value —
                        // the rest of the ListView is untouched.
                        return ValueListenableBuilder<StreamingBubbleState?>(
                          valueListenable: notifier.streamingBubble,
                          builder: (context, streaming, _) {
                            if (streaming != null) {
                              return _StreamingBubble(
                                notifier: notifier,
                                coach: coach,
                                onRetry: _retryStreamingDrop,
                              );
                            }
                            // No tokens yet — show the existing typing
                            // indicator with its 1-Hz elapsed label (C5).
                            return _TypingIndicator(
                              statusText: _statusLabel,
                              elapsedListenable: _elapsedNotifier,
                            );
                          },
                        );
                      }

                      // Loading-more indicator at the END (visually at top in reversed list)
                      final lastIndex = messages.length + extraItems - 1;
                      if (hasMore && index == lastIndex) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      }

                      // Offset by 1 if the newest slot (streaming bubble /
                      // typing indicator) is occupying index 0.
                      final msgIndex = messages.length - 1 - (index - (hasNewestSlot ? 1 : 0));
                      if (msgIndex < 0 || msgIndex >= messages.length) {
                        return const SizedBox.shrink();
                      }
                      final message = messages[msgIndex];
                      // Find the previous user message for context when reporting
                      String? previousUserMessage;
                      if (message.role == 'assistant') {
                        for (int i = msgIndex - 1; i >= 0; i--) {
                          if (messages[i].role == 'user') {
                            previousUserMessage = messages[i].content;
                            break;
                          }
                        }
                      }

                      // Date separator: In a reversed list, index 0 = newest (bottom).
                      // Show a date header above the FIRST message of each day group.
                      // In reversed order, check if the NEWER message (index-1, visually
                      // below) belongs to a different day. If so, this message is the
                      // last of its day group (visually topmost), so place the header here.
                      Widget? dateSeparator;
                      final newerIndex = msgIndex - 1;
                      if (newerIndex >= 0) {
                        final currentDate = message.timestamp ?? DateTime.now();
                        final newerDate = messages[newerIndex].timestamp ?? DateTime.now();
                        if (!_isSameDay(currentDate, newerDate)) {
                          dateSeparator = _buildDateSeparator(currentDate);
                        }
                      }
                      // Always show header for the newest message group (index 0)
                      if (msgIndex == 0) {
                        dateSeparator = _buildDateSeparator(message.timestamp ?? DateTime.now());
                      }

                      final bubble = ChatMessageBubble(
                        key: ValueKey(message.id ?? 'msg_$msgIndex'),
                        message: message,
                        previousUserMessage: previousUserMessage,
                        coach: coach,
                        onLogAnalysisItems: _logAnalysisItems,
                        onRetry: (message.role == 'error' || message.status == MessageStatus.error)
                            ? () => _retryMessage(messages, msgIndex)
                            : null,
                        onRegenerate: message.role == 'assistant' ? () => _regenerateResponse(messages, msgIndex) : null,
                        onEquipmentMatchTap: _handleEquipmentMatchTap,
                        onCreateCustomFromEquipment: _handleCreateCustomFromEquipment,
                        onStartWorkoutWithEquipment: _handleStartWorkoutWithEquipment,
                        // SuggestedActionsCard's "Check my form" chip → reuse
                        // the existing pill video-picker bridge (record path).
                        onAttachFormVideo: () => _handleMediaFromPill(
                          ChatMediaMode.recordVideo,
                          'Can you check my form?',
                        ),
                      ).animate().fadeIn(duration: 200.ms);

                      // Highlight animation for scroll-to-message
                      final isHighlighted = _highlightedMessageId != null && message.id == _highlightedMessageId;
                      final wrappedBubble = isHighlighted
                          ? Container(
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: bubble,
                            )
                          : bubble;

                      // Plan §1c.5 — render the suggested-reply chip
                      // strip directly below the seeded coach turn so
                      // the conversation reads "card spoke, you answer."
                      // The marker we look for is the same one
                      // `_seedInsightCoachTurn` stamps in `intent`.
                      Widget? chipsStrip;
                      final isSeededInsightTurn = widget.insightId != null &&
                          widget.insightId!.isNotEmpty &&
                          message.intent == 'insight:${widget.insightId}';
                      if (isSeededInsightTurn) {
                        chipsStrip = _buildSuggestedChipsStrip();
                      }

                      Widget body = wrappedBubble;
                      if (chipsStrip != null) {
                        body = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [wrappedBubble, chipsStrip],
                        );
                      }

                      if (dateSeparator != null) {
                        // Column renders top-to-bottom even inside a reversed ListView.
                        // Separator above, bubble below.
                        return Column(
                          children: [dateSeparator, body],
                        );
                      }
                      return body;
                    },
                  );
                },
              ),
            ),
              // Scroll-to-bottom FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: AnimatedScale(
                  scale: _showScrollFAB ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    heroTag: 'scroll_to_bottom',
                    backgroundColor: AppColors.elevated,
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          ),

          // Low usage warning strip
          Builder(builder: (context) {
            final usageState = ref.watch(usageTrackingProvider);
            if (usageState.isPremium) return const SizedBox.shrink();
            final feature = usageState.limits[_kAiChatMessages];
            if (feature == null) return const SizedBox.shrink();
            final remaining = feature.remaining ?? ((feature.limit ?? 0) - feature.used);
            final limit = feature.limit ?? 0;
            if (remaining > 5 || remaining <= 0 || limit == 0) return const SizedBox.shrink();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.warning.withOpacity(isDark ? 0.15 : 0.1),
              child: Text(
                l10n.chatScreenMessagesLeftToday(remaining),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.warning : Colors.orange.shade800,
                ),
              ),
            );
          }),

          // Medical disclaimer
          const MedicalDisclaimerBanner(),

          // Quick action pills
          ChatQuickPills(
            onSendPrompt: (prompt) {
              _textController.text = prompt;
              _sendMessage();
            },
            onOpenMediaPicker: (mode, contextPrompt) =>
                _handleMediaFromPill(mode, contextPrompt),
            isLoading: _isLoading,
          ),

          // Input bar
          _InputBar(
            controller: _textController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
            onSendWithMedia: _sendMessageWithMedia,
            onSendWithMultiMedia: _sendMessageWithMultiMedia,
            onSendVoiceMessage: _sendVoiceMessage,
            isOffline: offlineChatState.isAvailable,
            modelName: offlineChatState.modelName,
          ),
        ],
      ),

      // Floating pill top bar — matches workout detail screen style
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Row(
          children: [
            // Back button circle
            GestureDetector(
              onTap: () {
                HapticService.light();
                context.pop();
              },
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Coach name + status — expanded pill
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Row(
                  children: [
                    if (showLoadingCoach)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark
                                  ? AppColors.cardBorder
                                  : AppColorsLight.cardBorder)
                              .withValues(alpha: 0.4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cyan,
                          ),
                        ),
                      )
                    else
                      CoachAvatar(
                        coach: coach,
                        size: 30,
                        showBorder: true,
                        showShadow: false,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            coachName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColorsLight.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _isLoading
                                      ? l10n.chatScreenTyping
                                      : offlineChatState.isAvailable
                                          ? l10n.agentInfoHeaderOffline
                                          : l10n.agentInfoHeaderOnline,
                                  style: TextStyle(fontSize: 11, color: statusColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Usage info button circle
            GestureDetector(
              onTap: () {
                HapticService.light();
                _showUsageInfoSheet(context);
              },
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: topBarColor,
                  borderRadius: BorderRadius.circular(22),
                  border: topBarBorder,
                  boxShadow: [topBarShadow],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                      size: 20,
                    ),
                    // Warning dot when messages are running low
                    Builder(builder: (context) {
                      final remaining = ref.watch(usageTrackingProvider).limits[_kAiChatMessages];
                      final left = remaining?.remaining ?? remaining?.limit;
                      if (left != null && left <= 5 && left > 0) {
                        return Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Search + More pill
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: topBarColor,
                borderRadius: BorderRadius.circular(22),
                border: topBarBorder,
                boxShadow: [topBarShadow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      final messagesData = ref.read(chatMessagesProvider).valueOrNull ?? [];
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatSearchOverlay(
                          messages: messagesData,
                          onScrollToMessage: (messageId) {
                            Navigator.of(context).pop();
                            _scrollToMessage(messageId);
                          },
                        ),
                      ));
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _showOptionsMenu(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    // Convert to local time so UTC timestamps compare correctly with local dates
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  // Issue 2 — real deeplink for EquipmentMatchCard match taps.
  //
  // Flow:
  //   1. Resolve today's workout (cache-first, instant).
  //   2. If a workout exists → drop a SWAP pending action and route to
  //      /active-workout. The active workout entry consumes the provider
  //      after first frame and opens the canonical swap sheet pre-targeted
  //      at the matched exercise.
  //   3. If no workout exists → surface a clear "Start a workout first"
  //      CTA bottom sheet (per feedback_no_silent_fallbacks). Tapping
  //      "Start" drops an ADD pending action and opens the quick-workout
  //      sheet so the matched exercise lands in a fresh session.
  void _handleEquipmentMatchTap(
    Map<String, dynamic> match,
    Map<String, dynamic> actionData,
  ) {
    final exerciseId = (match['id'] as String?) ??
        (match['exercise_id'] as String?) ??
        '';
    final matchName = (match['name'] as String?) ?? '';
    final imageUrl = match['image_url'] as String?;
    final primaryMuscle = match['primary_muscle'] as String?;
    if (exerciseId.isEmpty || matchName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This match is missing an exercise id.")),
      );
      return;
    }

    // Read today's workout from cache. todayWorkoutProvider is cache-first,
    // so this is synchronous and feels immediate (no network round-trip).
    final todayAsync = ref.read(todayWorkoutProvider);
    final today = todayAsync.valueOrNull;
    final hasActiveWorkout = today?.todayWorkout != null &&
        !(today!.todayWorkout!.isCompleted);

    if (hasActiveWorkout) {
      ref.read(equipmentMatchPendingActionProvider.notifier).state =
          EquipmentMatchPendingAction(
        mode: EquipmentMatchPendingMode.swap,
        exerciseId: exerciseId,
        exerciseName: matchName,
        exerciseImageUrl: imageUrl,
        primaryMuscle: primaryMuscle,
      );
      // Hand off to the canonical workout route. The summary->Workout
      // bridge expects an extra payload, so pass the today summary's full
      // Workout object — the route already handles both Workout and Map.
      final workoutObj = today.todayWorkout!.toWorkout();
      context.push('/active-workout', extra: workoutObj);
      return;
    }

    // No active workout — never silently no-op. Surface a clear CTA.
    showGlassSheet<void>(
      context: context,
      opaque: true,
      builder: (sheetCtx) {
        return GlassSheet(
          opaque: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fitness_center_rounded,
                    color: AppColors.cyan, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Start a workout to use $matchName',
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You don't have a workout in progress yet. Start a quick "
                  "workout and we'll drop $matchName right in.",
                  style: Theme.of(sheetCtx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: const Text('Not now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          // Seed an ADD action — the new quick workout will
                          // not have an existing exercise to swap against.
                          ref
                              .read(equipmentMatchPendingActionProvider
                                  .notifier)
                              .state = EquipmentMatchPendingAction(
                            mode: EquipmentMatchPendingMode.add,
                            exerciseId: exerciseId,
                            exerciseName: matchName,
                            exerciseImageUrl: imageUrl,
                            primaryMuscle: primaryMuscle,
                          );
                          Navigator.of(sheetCtx).pop();
                          showQuickWorkoutSheet(context, ref);
                        },
                        child: const Text('Start workout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCreateCustomFromEquipment(Map<String, dynamic> actionData) {
    final canonical = actionData['canonical_name'] as String?;
    final s3Key = actionData['snapped_equipment_s3_key'] as String?
        ?? actionData['s3_key'] as String?;
    showImportExerciseScreen(
      context,
      prefilledImageS3Key: s3Key,
      prefilledNameHint: canonical,
    );
  }

  void _handleStartWorkoutWithEquipment(Map<String, dynamic> actionData) {
    showQuickWorkoutSheet(context, ref);
  }

  void _retryMessage(List<ChatMessage> messages, int errorIndex) {
    // Find the user message that preceded this error
    String? userMessage;
    for (int i = errorIndex - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        userMessage = messages[i].content;
        break;
      }
    }
    if (userMessage == null || userMessage.isEmpty) return;

    // Remove the error bubble from local state unconditionally. Client-side
    // error bubbles typically have no server id, so the old id-guarded
    // deleteMessage path left the error bubble visible even after a successful
    // retry — confusing because the chat then showed [user][error][user][reply].
    final errorMsg = messages[errorIndex];
    final notifier = ref.read(chatMessagesProvider.notifier);
    final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
    final cleaned = current.where((m) => !identical(m, errorMsg) && !(
        m.role == errorMsg.role &&
        m.content == errorMsg.content &&
        m.createdAt == errorMsg.createdAt)).toList();
    if (cleaned.length != current.length) {
      notifier.state = AsyncValue.data(cleaned);
    }
    if (errorMsg.id != null) {
      notifier.deleteMessage(errorMsg.id!); // Fire-and-forget server cleanup
    }

    _textController.text = userMessage;
    _sendMessage();
  }

  /// Regenerate an AI response by removing it and resending the previous user message
  Future<void> _regenerateResponse(List<ChatMessage> messages, int aiMsgIndex) async {
    // Find the previous user message
    String? userMessage;
    for (int i = aiMsgIndex - 1; i >= 0; i--) {
      if (messages[i].role == 'user') {
        userMessage = messages[i].content;
        break;
      }
    }
    if (userMessage == null || userMessage.isEmpty) return;

    // Remove the AI response and await completion before resending
    final aiMsg = messages[aiMsgIndex];
    if (aiMsg.id != null) {
      await ref.read(chatMessagesProvider.notifier).deleteMessage(aiMsg.id!);
      // deleteMessage round-trips to the server. If the user popped the chat
      // during that hop we must NOT touch ref or trigger _sendMessage again.
      if (!mounted) return;
    } else {
      final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
      final updated = current.where((m) => m != aiMsg).toList();
      ref.read(chatMessagesProvider.notifier).state = AsyncValue.data(updated);
    }

    // Resend the user message
    _textController.text = userMessage;
    _sendMessage();
  }

  void _showFeaturesInfoSheet() {
    showGlassSheet(
      context: context,
      builder: (context) => ChatFeaturesInfoSheet(
        onAction: (action) => _handleQuickAction(action),
      ),
    );
  }

  void _handleQuickAction(ChatQuickAction action) {
    if (_isLoading) return;

    // Premium gate: check form video analysis actions
    if (_formVideoActions.contains(action.id)) {
      final notifier = ref.read(usageTrackingProvider.notifier);
      if (!notifier.hasAccess(_kFormVideoAnalysis)) {
        showUpgradePromptSheet(context,
            featureKey: _kFormVideoAnalysis,
            featureName: 'Form Video Analysis');
        return;
      }
    }

    // Premium gate: check food scanning actions
    if (_foodScanActions.contains(action.id)) {
      final notifier = ref.read(usageTrackingProvider.notifier);
      if (!notifier.hasAccess(_kFoodScanning)) {
        showUpgradePromptSheet(context,
            featureKey: _kFoodScanning, featureName: 'Food Scans');
        return;
      }
    }

    if (action.behavior == ChatActionBehavior.sendPrompt && action.prompt != null) {
      _textController.text = action.prompt!;
      _sendMessage();
    } else if (action.behavior == ChatActionBehavior.openMediaPicker) {
      _showMiniMediaChoiceForAction(action);
    }
  }

  void _showEscalateToHumanDialog() {
    showDialog(
      context: context,
      builder: (_) => const _EscalateToHumanDialog(),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all your conversation history with the AI coach. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatMessagesProvider.notifier).clearHistory();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final aiSettings = ref.read(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Row(
          children: [
            CoachAvatar(
              coach: coach,
              size: 40,
              showBorder: true,
              showShadow: false,
              enableTapToView: false, // Already in a dialog
            ),
            const SizedBox(width: 12),
            Text(coach.name),
          ],
        ),
        content: const Text(
          'Your personal AI-powered fitness coach. Ask about workouts, nutrition, recovery, or any fitness-related questions. The AI learns from your progress to give personalized advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// _MediaUploadOverlay and _FoodAnalysisSummaryCard extracted to widgets/chat_media_widgets.dart
