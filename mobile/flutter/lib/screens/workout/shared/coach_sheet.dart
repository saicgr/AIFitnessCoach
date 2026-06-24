/// Inline 60 %-height AI-coach chat sheet — shared between Easy and Advanced.
///
/// Streams from the existing `chatMessagesProvider` (same code path the main
/// Chat tab uses), so LangGraph's Workout-agent routing and `action_data`
/// handlers (swap exercise, adjust weight, add/remove set) come along for free.
///
/// Originally lived at `simple/widgets/simple_chat_bar.dart` when the app had a
/// Simple tier. That tier was retired and the sheet moved here verbatim; only
/// the public names were shortened (`showSimpleCoachSheet` →
/// `showCoachSheet`, `SimpleCoachSheet` → `CoachSheet`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat_message.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/glass_sheet.dart';
import '../../ai_settings/ai_settings_screen.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Default quick replies — balanced framing for general use.
const kCoachQuickReplies = <String>[
  'Is this too heavy?',
  'Swap this exercise',
  'Form tips',
  "I'm tired",
];

/// Beginner-tuned quick replies used by the Easy tier.
const kEasyCoachQuickReplies = <String>[
  'Is this too heavy?',
  'What does this exercise do?',
  'Swap this exercise',
  "I'm tired, what now?",
];

/// Opens the inline coach sheet.
Future<void> showCoachSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
  List<String> quickReplies = kCoachQuickReplies,
}) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: false,
      child: CoachSheet(
        exercise: exercise,
        quickReplies: quickReplies,
      ),
    ),
  );
}

class CoachSheet extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final List<String> quickReplies;
  const CoachSheet({
    super.key,
    required this.exercise,
    this.quickReplies = kCoachQuickReplies,
  });

  @override
  ConsumerState<CoachSheet> createState() => _CoachSheetState();
}

class _CoachSheetState extends ConsumerState<CoachSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(msg);
      _controller.clear();
    } catch (e) {
      debugPrint('❌ [CoachSheet] sendMessage failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF151515) : Colors.white;
    final fg = isDark ? Colors.white : Colors.black87;
    final muted = fg.withOpacity(0.6);
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.6;

    final msgs = ref.watch(chatMessagesProvider).valueOrNull ?? const [];

    // The user's actual selected coach persona (same source as the main Chat
    // tab) — so the in-workout sheet shows OUR coach (avatar + name), not a
    // generic 🎭 placeholder.
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach =
        CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: fg.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 12, 4),
            child: Row(children: [
              CoachAvatar(
                coach: coach,
                size: 30,
                showBorder: true,
                showShadow: false,
                enableTapToView: false,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(coach.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                  Text(AppLocalizations.of(context).easyChatPillAskYourCoach,
                      style: TextStyle(fontSize: 11.5, color: muted)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: fg),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(child: _buildMessageList(msgs, fg, muted, coach)),
          _buildQuickChips(muted),
          _buildInputRow(fg, muted, isDark),
          SizedBox(height: media.viewInsets.bottom > 0 ? 8 : 12),
        ]),
      ),
    );
  }

  Widget _buildMessageList(
      List<ChatMessage> msgs, Color fg, Color muted, CoachPersona coach) {
    final recent = msgs.length <= 6 ? msgs : msgs.sublist(msgs.length - 6);
    // Empty state — a real coach greeting referencing the current exercise so
    // the sheet never opens as a blank void (which read as "not the real
    // coach"). Messages route through the same context-rich chat pipeline.
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CoachAvatar(
              coach: coach,
              size: 56,
              showBorder: true,
              showShadow: false,
              enableTapToView: false,
            ),
            const SizedBox(height: 14),
            Text(
              "Hey, I'm ${coach.name}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: fg),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask me anything about ${widget.exercise.name} — form, weight, '
              'swaps, or how you’re feeling. I can see your workout.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: recent.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (c, i) {
          final m = recent[i];
          final isUser = m.role == 'user';
          return Align(
            alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(c).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? fg.withOpacity(0.08)
                    : muted.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(m.content,
                  style: TextStyle(fontSize: 13, color: fg)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChips(Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.quickReplies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (c, i) {
            final q = widget.quickReplies[i];
            return ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 12)),
              onPressed: _sending ? null : () => _send(q),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputRow(Color fg, Color muted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(fontSize: 14, color: fg),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).coachAskAnything,
              hintStyle: TextStyle(color: muted, fontSize: 14),
              filled: true,
              fillColor:
                  (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: _sending ? null : _send,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _sending ? null : () => _send(_controller.text),
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
        ),
      ]),
    );
  }
}
