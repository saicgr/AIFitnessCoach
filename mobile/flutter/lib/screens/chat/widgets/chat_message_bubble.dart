import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/models/cosmetic.dart';
import '../../../data/providers/cosmetics_provider.dart';
import '../../../widgets/coach_avatar.dart';
import 'food_analysis_inline_card.dart';
import 'generic_blocks_renderer.dart';
import 'food_analysis_result_card.dart';
import 'form_check_result_card.dart';
import 'form_comparison_result_card.dart';
import 'fullscreen_image_viewer.dart';
import 'proposed_change_card.dart';
import 'chat_action_confirm_card.dart';
import 'equipment_match_card.dart';
import 'event_logged_undo_card.dart';
import 'share_artifact_card.dart';
import 'suggested_actions_card.dart';
import 'report_message_sheet.dart';
import 'voice_message_widget.dart';
import 'chat_media_widgets.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../data/services/chat_action_summary_builder.dart';
/// A single chat message bubble (user, assistant, system, or error)
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final String? previousUserMessage;
  final CoachPersona coach;
  final void Function(List<Map<String, dynamic>>)? onLogAnalysisItems;
  final VoidCallback? onRetry;
  final VoidCallback? onRegenerate;
  // Issue 2: invoked when the user taps a row in EquipmentMatchCard.
  // The parent (chat_screen / inline_workout_chat) holds the active
  // workout context and decides between Swap / Add / quick-workout.
  final void Function(Map<String, dynamic> match, Map<String, dynamic> actionData)? onEquipmentMatchTap;
  final void Function(Map<String, dynamic> actionData)? onCreateCustomFromEquipment;
  final void Function(Map<String, dynamic> actionData)? onStartWorkoutWithEquipment;
  /// Bridges the SuggestedActionsCard's `attach_form_video` chip to the chat
  /// screen's own video picker (the card can't open it itself). Null outside
  /// the chat screen → the chip is hidden.
  final VoidCallback? onAttachFormVideo;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.coach,
    this.previousUserMessage,
    this.onLogAnalysisItems,
    this.onRetry,
    this.onRegenerate,
    this.onEquipmentMatchTap,
    this.onCreateCustomFromEquipment,
    this.onStartWorkoutWithEquipment,
    this.onAttachFormVideo,
  });

  /// IDs to suppress in the SuggestedActionsCard because this same message
  /// already rendered their result — e.g. don't offer "Scan Menu" right under
  /// a menu-analysis result, or "Check my form" under a form-check result.
  Set<String> get _suppressedSuggestionIds {
    final action = message.actionData?['action'];
    final out = <String>{};
    if (message.hasMenuAnalysis || action == 'analyze_menu') {
      out.add('scan_menu');
    }
    if (message.hasFoodAnalysis ||
        message.hasBuffetAnalysis ||
        message.hasFoodLogged ||
        action == 'analyze_multi_food_images') {
      out.addAll(const {
        'photo_food',
        'scan_food',
        'food',
        'barcode_food',
        'scan_menu',
        'scan_nutrition_label',
        'scan_app_screenshot',
      });
    }
    if (message.hasFormCheckResult || message.hasFormComparison) {
      out.add('attach_form_video');
    }
    if (message.hasGeneratedWorkout) {
      out.add('quick_workout');
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';
    final isError = message.role == 'error';

    final messageCoach = (message.coachPersonaId != null
        ? CoachPersona.findById(message.coachPersonaId)
        : null) ?? coach;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    if (isError) {
      return _buildErrorMessage(context);
    }

    Widget bubbleContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.cyan : AppColors.elevated,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isUser ? const Radius.circular(4) : null,
          bottomLeft: !isUser ? const Radius.circular(4) : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoachAvatar(
                    coach: messageCoach,
                    size: 20,
                    showBorder: true,
                    borderWidth: 1,
                    showShadow: false,
                    enableTapToView: false,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    messageCoach.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: messageCoach.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          // Media thumbnail for user messages
          if (isUser && message.hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: message.mediaType != 'video'
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              imageUrl: message.mediaUrl,
                              localFilePath: message.localFilePath,
                              // Match the bubble's Hero tag exactly. Suffixing
                              // with identityHashCode guarantees uniqueness
                              // even when two messages briefly share the same
                              // id (e.g. optimistic-send + server echo).
                              heroTag:
                                  'chat_media_${message.id}_${identityHashCode(message)}',
                            ),
                          ),
                        )
                    : null,
                child: Hero(
                  tag:
                      'chat_media_${message.id}_${identityHashCode(message)}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        children: [
                          if (message.localFilePath != null)
                            Image.file(
                              File(message.localFilePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          else if (message.mediaUrl != null)
                            CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              placeholder: (_, __) => Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(
                                    message.mediaType == 'video' ? Icons.videocam : Icons.image,
                                    size: 32,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          if (message.uploadPhase != null)
                            Positioned.fill(
                              child: MediaUploadOverlay(
                                phase: message.uploadPhase!,
                                progress: message.uploadProgress,
                              ),
                            )
                          else if (message.mediaType == 'video')
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                              ),
                            ),
                          if (isUser && message.mediaRefs != null && message.mediaRefs!.length > 1)
                            PositionedDirectional(bottom: 4,
                              end: 4,
                              child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.chatMessageBubbleValue(message.mediaRefs!.length - 1),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Upload progress indicator
          if (isUser && !message.hasMedia && message.mediaType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 48,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.pureBlack.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).storyCreateUploading,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.pureBlack.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (message.isVoiceMessage)
            VoiceMessageBubble(
              audioUrl: message.audioUrl!,
              durationMs: message.audioDurationMs ?? 0,
            )
          else if (isUser && message.content.contains('[ACTIVE WORKOUT CONTEXT]'))
            _WorkoutContextMessage(
              content: message.content,
              textColor: AppColors.pureBlack,
            )
          else
            Text(
              // Defensive: strip any stray legacy action tokens (e.g.
              // "action navigate destination support") that occasionally
              // leak through from older agent prompts. The /support route
              // does not exist; show_options chips render below instead.
              _scrubLegacyActionTokens(message.content),
              style: TextStyle(
                color: isUser ? AppColors.pureBlack : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          // ── Contact / option chips (action: "show_options") ─────────────
          // Used by the "need help" flow — the coach offers Discord / Email
          // / Instagram. Each chip launches the URL externally via
          // url_launcher; we never navigate to a /support route.
          if (!isUser && message.actionData?['action'] == 'show_options')
            _buildShowOptions(context, message.actionData!),
          if (!isUser && message.hasFormCheckResult)
            FormCheckResultCard(result: message.formCheckResult!),
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length <= 5)
            FoodAnalysisInlineCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onLogItems: onLogAnalysisItems != null
                  ? (items) => onLogAnalysisItems!(items)
                  : (_) {},
            ),
          if (!isUser && message.hasFoodAnalysis &&
              (message.actionData!['food_items'] as List).length > 5)
            FoodAnalysisSummaryCard(
              foodItems: (message.actionData!['food_items'] as List)
                  .cast<Map<String, dynamic>>(),
              onViewAll: onLogAnalysisItems,
            ),
          if (!isUser && (message.hasBuffetAnalysis || message.hasMenuAnalysis ||
              (message.actionData?['action'] == 'analyze_multi_food_images')))
            FoodAnalysisResultCard(
              data: message.actionData!,
              onLogItems: onLogAnalysisItems != null ? (items) => onLogAnalysisItems!(items) : null,
            ),
          if (!isUser && message.hasFormComparison)
            FormComparisonResultCard(data: message.actionData!),
          if (!isUser &&
              message.actionData?['action'] == 'share_artifact_generated')
            ShareArtifactCard(data: message.actionData!),
          // ── Phase 6: universal-logging undo card ──────────────────────
          // After the AI Coach logs a wellness event ("I did 30 min yoga"),
          // show a compact "Logged ✓ · Undo" row per event. Backed by the
          // signed undo_token; self-disables after the 30s token window.
          if (!isUser && message.actionData?['action'] == 'event_logged')
            EventLoggedUndoCard(
              actionData: Map<String, dynamic>.from(message.actionData!),
            ),
          // ── Issue 2: Equipment match card ──────────────────────────
          // Rendered when the identify_equipment tool returns
          // action='open_swap_or_add'. Tapping a match row hands off to
          // the parent so it can deeplink into Swap / Add / quick-workout.
          if (!isUser &&
              message.actionData?['action'] == 'open_swap_or_add')
            EquipmentMatchCard(
              actionData: Map<String, dynamic>.from(message.actionData!),
              onMatchTap: (match) {
                onEquipmentMatchTap?.call(
                  match,
                  Map<String, dynamic>.from(message.actionData!),
                );
              },
              onCreateCustom: onCreateCustomFromEquipment != null
                  ? () => onCreateCustomFromEquipment!(
                        Map<String, dynamic>.from(message.actionData!),
                      )
                  : null,
              onStartWorkoutWithEquipment: onStartWorkoutWithEquipment != null
                  ? () => onStartWorkoutWithEquipment!(
                        Map<String, dynamic>.from(message.actionData!),
                      )
                  : null,
            ),
          // ── Issue 3: AI-coach mutation confirm card ───────────────
          // For actions that mutate the workout and require explicit
          // user confirmation (log_set, swap_exercise, supersets,
          // reorder), render an Apply / Cancel card. Auto-cancels
          // after 90s.
          if (!isUser &&
              message.actionData != null &&
              const {
                'swap_exercise',
                'log_set',
                'create_superset',
                'break_superset',
                'reorder_exercises',
              }.contains(message.actionData!['action'] as String?) &&
              (message.actionData!['requires_confirmation'] == true ||
                  message.actionData!['action'] == 'swap_exercise' ||
                  message.actionData!['action'] == 'reorder_exercises' ||
                  message.actionData!['action'] == 'log_set'))
            ChatActionConfirmCard(
              actionData: Map<String, dynamic>.from(message.actionData!),
              summaryText: ChatActionSummaryBuilder.build(context, message.actionData) ??
                  (message.actionData!['summary_text'] as String?) ??
                  _scrubLegacyActionTokens(message.content),
            ),
          if (!isUser && message.hasProposedChange)
            ProposedChangeCard(
              proposalId: message.proposalId!,
              proposalToken: message.proposalToken ?? '',
              summary: message.proposalSummary ?? 'Proposed change',
              reason: message.proposalReason,
              proposedAction: message.proposalProposedAction,
              expiresAt: message.proposalExpiresAt,
            ),
          if (!isUser && message.hasGeneratedWorkout)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: WorkoutResultCard(
                workoutId: message.workoutId!,
                workoutName: message.workoutName,
                durationMinutes:
                    (message.actionData?['duration_minutes'] as num?)?.toInt(),
                exerciseCount:
                    (message.actionData?['exercise_count'] as num?)?.toInt(),
                exerciseNames:
                    (message.actionData?['exercises_added'] is List)
                        ? List<String>.from(
                            (message.actionData!['exercises_added'] as List)
                                .map((e) => e.toString()))
                        : const [],
              ),
            ),
          if (!isUser && message.hasFoodLogged)
            ViewLoggedMealButton(
              mealType: message.loggedMealType,
              calories: message.loggedMealCalories,
            ),
          // ── Suggested-action launcher chips ───────────────────────────
          // Tappable shortcuts the coach surfaces (scan a menu, check form,
          // browse workouts…). Rides alongside any result card above, so it
          // renders independent of the primary `action`. The card itself
          // filters to the allowlist, dedupes, caps, and renders nothing if
          // everything is suppressed/unknown.
          if (!isUser && message.hasSuggestedActions)
            SuggestedActionsCard(
              actionIds: message.suggestedActionIds,
              prompt: message.suggestedActionsPrompt,
              excludeIds: _suppressedSuggestionIds,
              onAttachFormVideo: onAttachFormVideo,
            ),
          // ── Generic in-chat blocks (metric cards, charts, stat grids) ──
          // Backend-driven structured blocks the coach emits alongside its
          // text reply. Rendered only for assistant messages that carry a
          // non-empty `blocks` list; legacy messages (null) skip this entirely.
          if (!isUser && message.blocks != null && message.blocks!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GenericBlocksRenderer(blocks: message.blocks!),
            ),
          // ── Inline "go-to" deep-link pills ────────────────────────────
          // When the coach references an entity (exercise, PR/progress,
          // hydration, body weight, schedulable workout, recipe), surface a
          // one-tap pill that deep-links to the right surface.
          if (!isUser && message.hasExerciseReference)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExerciseHowToButton(
                exerciseId: message.referencedExerciseId,
                exerciseName: message.referencedExerciseName ?? 'this exercise',
              ),
            ),
          if (!isUser && message.hasProgressReference)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ViewProgressButton(
                kind: message.progressReferenceKind,
                exerciseName: message.progressExerciseName,
              ),
            ),
          if (!isUser && message.hasHydrationLog)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LogWaterButton(),
            ),
          if (!isUser && message.hasWeightLogPrompt)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LogWeightButton(),
            ),
          if (!isUser && message.hasScheduleWorkout)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScheduleWorkoutButton(workoutId: message.workoutId!),
            ),
          if (!isUser && message.hasRecipeReference)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ViewRecipeButton(recipe: message.referencedRecipe!),
            ),
          // Timestamp + delivery status (assistant messages also show latency)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? AppColors.pureBlack.withOpacity(0.6)
                        : AppColors.textMuted,
                  ),
                ),
                if (!isUser && message.responseTimeMs != null) ...[
                  Text(
                    ' · ${_formatResponseTime(message.responseTimeMs!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (isUser) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
          if (!isUser && message.actionData?['offline'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Generated offline by ${message.actionData?['model'] ?? 'Local AI'}',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: isUser
                      ? AppColors.pureBlack.withOpacity(0.4)
                      : AppColors.textMuted.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );

    bubbleContent = GestureDetector(
      onLongPress: () {
        HapticService.medium();
        _showMessageContextMenu(context, ref, isUser);
      },
      child: bubbleContent,
    );

    // Equipped chat title pill rendered above user messages (earned via cosmetics)
    Widget? titlePill;
    if (isUser) {
      final cosmetics = ref.watch(cosmeticsProvider);
      Cosmetic? equippedTitle;
      for (final c in cosmetics.catalog) {
        if (c.type == CosmeticType.chatTitle && (cosmetics.owned[c.id]?.isEquipped ?? false)) {
          equippedTitle = c;
          break;
        }
      }
      if (equippedTitle != null) {
        final primary = equippedTitle.color ?? AppColors.cyan;
        titlePill = Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 4, end: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, (equippedTitle.gradient ?? primary)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (equippedTitle.emoji != null) ...[
                  Text(equippedTitle.emoji!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                ],
                Text(
                  equippedTitle.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (titlePill != null) titlePill,
          bubbleContent,
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    final statusColor = AppColors.pureBlack.withOpacity(0.5);
    switch (status) {
      case MessageStatus.pending:
        return Icon(Icons.access_time, size: 10, color: statusColor);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 10, color: statusColor);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 10, color: AppColors.cyan);
      case MessageStatus.error:
        return const Icon(Icons.close, size: 10, color: AppColors.error);
    }
  }

  void _showMessageContextMenu(BuildContext context, WidgetRef ref, bool isUser) {
    showGlassSheet<void>(
      context: context,
      builder: (ctx) {
        return GlassSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: Text(AppLocalizations.of(context).milestoneCelebrationCopy),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).chatMessageBubbleCopied),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                if (!isUser && onRegenerate != null)
                  ListTile(
                    leading: const Icon(Icons.refresh, size: 20),
                    title: Text(AppLocalizations.of(context).workoutActionsRegenerate),
                    onTap: () {
                      Navigator.pop(ctx);
                      onRegenerate!();
                    },
                  ),
                if (message.id != null)
                  ListTile(
                    leading: Icon(
                      message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    title: Text(message.isPinned ? AppLocalizations.of(context).pinnedMessageBarUnpin : AppLocalizations.of(context).menuAnalysisHistoryPin),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(chatMessagesProvider.notifier).togglePin(message.id!);
                    },
                  ),
                if (isUser)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    title: Text(AppLocalizations.of(context).buttonDelete, style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: Text(AppLocalizations.of(context).chatMessageBubbleDeleteThisMessage),
                          content: Text(AppLocalizations.of(context).workoutActionsThisActionCannotBe),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlgCtx),
                              child: Text(AppLocalizations.of(context).buttonCancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dlgCtx);
                                if (message.id != null) {
                                  ref.read(chatMessagesProvider.notifier).deleteMessage(message.id!);
                                } else {
                                  final current = ref.read(chatMessagesProvider).valueOrNull ?? [];
                                  final updated = current.where((m) => m != message).toList();
                                  ref.read(chatMessagesProvider.notifier).state = AsyncValue.data(updated);
                                }
                              },
                              child: Text(AppLocalizations.of(context).buttonDelete, style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!isUser)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, size: 20, color: AppColors.orange),
                    title: Text(AppLocalizations.of(context).logMealSheetReport),
                    onTap: () {
                      Navigator.pop(ctx);
                      showReportMessageSheet(
                        context,
                        messageId: message.id,
                        originalUserMessage: previousUserMessage ?? '',
                        aiResponse: message.content,
                      );
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.red.withOpacity(0.1)
              : Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18,
                    color: isDark ? Colors.red[300] : Colors.red[600]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.content,
                    style: TextStyle(fontSize: 13,
                        color: isDark ? Colors.red[300] : Colors.red[700]),
                  ),
                ),
              ],
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 14,
                      color: isDark ? Colors.red[300] : Colors.red[600]),
                  label: Text(AppLocalizations.of(context).buttonRetry,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.red[300] : Colors.red[600])),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.cardBorder.withOpacity(0.5)
                : AppColorsLight.cardBorder.withOpacity(0.5),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
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

  /// Format a user-perceived latency for display next to the timestamp.
  /// Buckets: sub-second → "Xms", under a minute → "X.Xs", else "Xm Ys".
  String _formatResponseTime(int ms) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) {
      final seconds = ms / 1000.0;
      return '${seconds.toStringAsFixed(1)}s';
    }
    final minutes = ms ~/ 60000;
    final remSeconds = (ms % 60000) ~/ 1000;
    return remSeconds == 0 ? '${minutes}m' : '${minutes}m ${remSeconds}s';
  }

  /// Strip stray legacy action tokens from a message body.
  ///
  /// Two leak shapes are scrubbed (defense in depth — the backend also strips
  /// these, but already-stored messages and any future regression must never
  /// render raw):
  ///  1. The legacy literal "action navigate destination support" fragment.
  ///  2. A tool-call envelope the model wrote as PROSE instead of calling the
  ///     tool — e.g. `{"action_ids": ["generate_quick_workout"], "prompt": ...}`
  ///     (the kettlebell JSON-leak bug). Only flat `{...}` blocks that look like
  ///     an action envelope are removed, so ordinary prose with braces (e.g.
  ///     "a deficit (about 500 kcal)") is left untouched.
  String _scrubLegacyActionTokens(String content) {
    final legacy = RegExp(
      r'\baction\s+navigate\s+destination\s+\w+\b',
      caseSensitive: false,
    );
    final leakedJson = RegExp(
      r'`{0,3}(?:json)?\s*\{[^{}]*?"(?:action_ids|action|suggested_actions)"\s*:[^{}]*\}\s*`{0,3}',
      caseSensitive: false,
      dotAll: true,
    );
    final scrubbed = content
        .replaceAll(leakedJson, ' ')
        .replaceAll(legacy, '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
    return scrubbed.isEmpty ? content : scrubbed;
  }

  /// Build the show_options chip row.
  ///
  /// `actionData["options"]` is a list of `{label, icon, url}` maps. Each
  /// chip launches the URL externally; failures are surfaced as a
  /// SnackBar (per feedback_no_silent_fallbacks.md — never silently swallow).
  Widget _buildShowOptions(BuildContext context, Map<String, dynamic> data) {
    final rawOptions = data['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    final prompt = data['prompt'] as String?;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prompt != null && prompt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                prompt,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rawOptions.whereType<Map>().map<Widget>((opt) {
              final label = (opt['label'] as String?) ?? 'Open';
              final iconKey = (opt['icon'] as String?)?.toLowerCase();
              final url = (opt['url'] as String?) ?? '';
              return ActionChip(
                avatar: Icon(_iconForKey(iconKey), size: 18),
                label: Text(label),
                onPressed: url.isEmpty
                    ? null
                    : () => _launchExternalUrl(context, url),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _iconForKey(String? key) {
    switch (key) {
      case 'discord':
        return Icons.forum_outlined;
      case 'email':
      case 'mail':
        return Icons.email_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      default:
        return Icons.open_in_new;
    }
  }

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        debugPrint('❌ [Chat] launchUrl returned false for $url');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open $url")),
        );
      }
    } catch (e) {
      debugPrint('❌ [Chat] launchUrl error for $url: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open $url")),
        );
      }
    }
  }
}

/// Displays a user message that contains [ACTIVE WORKOUT CONTEXT].
/// Shows only the user's question with a collapsible context chip.
class _WorkoutContextMessage extends StatefulWidget {
  final String content;
  final Color textColor;

  const _WorkoutContextMessage({
    required this.content,
    required this.textColor,
  });

  @override
  State<_WorkoutContextMessage> createState() => _WorkoutContextMessageState();
}

class _WorkoutContextMessageState extends State<_WorkoutContextMessage>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  /// Extract the user's actual question from the context block.
  (String userQuestion, List<(String, String)> contextItems) _parse() {
    final lines = widget.content.split('\n');
    String userQuestion = widget.content;
    final contextItems = <(String, String)>[];

    final questionIndex = lines.indexWhere((l) => l.startsWith('User question:'));
    if (questionIndex != -1) {
      userQuestion = lines[questionIndex].replaceFirst('User question: ', '').trim();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('---') || trimmed.isEmpty) continue;
      if (trimmed.startsWith('User question:')) continue;
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx > 0 && colonIdx < trimmed.length - 1) {
        contextItems.add((trimmed.substring(0, colonIdx).trim(), trimmed.substring(colonIdx + 1).trim()));
      }
    }
    return (userQuestion, contextItems);
  }

  @override
  Widget build(BuildContext context) {
    final (userQuestion, contextItems) = _parse();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User's actual question
        Text(
          userQuestion,
          style: TextStyle(
            color: widget.textColor,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        // Collapsible context chip
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 12,
                  color: widget.textColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context).chatMessageBubbleWorkoutContext,
                  style: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: widget.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded context details
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (label, value) in contextItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.chatMessageBubbleValue2(label),
                            style: TextStyle(
                              color: widget.textColor.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              value,
                              style: TextStyle(
                                color: widget.textColor.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
