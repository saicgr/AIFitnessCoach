import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/api_client.dart';
import '../pre_auth_quiz_data.dart' show preAuthQuizProvider;
import 'coach_preview_content.dart';

/// One message in a preview transcript.
class PreviewMsg {
  final bool isUser;
  final bool isLive;
  final String text;

  /// Small italic label rendered above the bubble (the visible fallback
  /// note — "Coach Mike's mid-set — here's how he answers that:").
  final String? noteAbove;

  const PreviewMsg(
    this.text, {
    required this.isUser,
    this.isLive = false,
    this.noteAbove,
  });
}

/// Per-coach preview conversation state. Owned by the SCREEN (not the page
/// widget) so transcripts survive PageView swipes and page disposal.
class CoachPreviewSession {
  final List<PreviewMsg> messages = [];
  final Set<int> askedChips = {};
  int liveUsed = 0;

  /// Live input retired after a visible failure (for this coach only).
  bool retired = false;

  /// Both live turns used — the close message asked them to commit.
  bool capped = false;

  /// Guards in-flight replies against coach switches / rapid sends.
  int flightToken = 0;
  bool typing = false;
  bool openerAdded = false;
}

/// Interactive "try your coach" chat — chips + a capped live turn.
///
/// The live input only renders when [liveEnabled] (PostHog kill switch
/// `onboarding_coach_live_chat`); chips and curated answers are the always-on
/// floor. Every failure path lands on curated content with a visible label —
/// never a spinner, never an error state.
class CoachPreviewChat extends ConsumerStatefulWidget {
  final CoachPersona coach;
  final CoachPreviewSession session;
  final bool liveEnabled;

  /// Fired when the second live turn completes — the screen pulses the CTA.
  final VoidCallback? onCapped;

  const CoachPreviewChat({
    super.key,
    required this.coach,
    required this.session,
    required this.liveEnabled,
    this.onCapped,
  });

  @override
  ConsumerState<CoachPreviewChat> createState() => _CoachPreviewChatState();
}

class _CoachPreviewChatState extends ConsumerState<CoachPreviewChat> {
  static const int _maxLiveTurns = 2;
  static const int _maxQuestionChars = 200;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  CoachPreviewSession get _s => widget.session;
  CoachPreviewContent get _content => previewContentFor(widget.coach.id);

  @override
  void initState() {
    super.initState();
    if (!_s.openerAdded) {
      _s.openerAdded = true;
      _s.messages.add(PreviewMsg(_content.opener, isUser: false));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<PreviewChip> get _chips {
    final limitations = ref.read(preAuthQuizProvider).limitations;
    return _content.chipsFor(limitations);
  }

  void _appendAndSettle(PreviewMsg msg) {
    if (!mounted) return;
    setState(() {
      _s.typing = false;
      _s.messages.add(msg);
    });
  }

  void _askChip(int index, PreviewChip chip) {
    HapticFeedback.selectionClick();
    final token = ++_s.flightToken;
    setState(() {
      _s.askedChips.add(index);
      _s.messages.add(PreviewMsg(chip.question, isUser: true));
      _s.typing = true;
    });
    ref.read(posthogServiceProvider).capture(
      eventName: 'coach_preview_question',
      properties: {
        'coach_id': widget.coach.id,
        'kind': chip.personalized ? 'chip_personalized' : 'chip',
      },
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || token != _s.flightToken) return;
      _appendAndSettle(PreviewMsg(chip.answer, isUser: false));
    });
  }

  Future<void> _sendLive() async {
    final q = _input.text.trim();
    if (q.isEmpty || _s.retired || _s.capped || _s.typing) return;
    HapticFeedback.selectionClick();
    _input.clear();

    final token = ++_s.flightToken;
    setState(() {
      _s.messages.add(PreviewMsg(q, isUser: true));
      _s.typing = true;
    });

    // Smalltalk: instant persona-voiced local reply. No live turn burned,
    // no API call made — greetings cost zero and can't fail.
    if (kPreviewGreeting.hasMatch(q)) {
      ref.read(posthogServiceProvider).capture(
        eventName: 'coach_preview_question',
        properties: {'coach_id': widget.coach.id, 'kind': 'greeting'},
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || token != _s.flightToken) return;
        _appendAndSettle(PreviewMsg(_content.greeting, isUser: false));
      });
      return;
    }

    final isFinalTurn = _s.liveUsed >= _maxLiveTurns - 1;
    ref.read(posthogServiceProvider).capture(
      eventName: 'coach_preview_question',
      properties: {'coach_id': widget.coach.id, 'kind': 'live'},
    );

    final quiz = ref.read(preAuthQuizProvider);
    final coach = widget.coach;
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(
            '/onboarding/coach-preview',
            data: {
              'coach_id': coach.id,
              'coach_name': coach.name,
              'coaching_style': coach.coachingStyle,
              'communication_tone': coach.communicationTone,
              'encouragement_level': coach.encouragementLevel,
              'question': q.length > _maxQuestionChars
                  ? q.substring(0, _maxQuestionChars)
                  : q,
              'final_turn': isFinalTurn,
              'context': {
                if (quiz.primaryGoal != null) 'goal': quiz.primaryGoal,
                if (quiz.fitnessLevel != null)
                  'fitness_level': quiz.fitnessLevel,
                if (quiz.workoutDays != null)
                  'days_per_week': quiz.workoutDays,
                if (limitationPhrase(quiz.limitations) != null)
                  'injuries': limitationPhrase(quiz.limitations),
              },
              'locale': Localizations.localeOf(context).languageCode,
            },
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted || token != _s.flightToken) return;
      final data = response.data ?? const <String, dynamic>{};
      final reply = (data['reply'] as String?)?.trim() ?? '';
      final isFallback = data['fallback'] == true || reply.isEmpty;

      if (isFallback) {
        _handleFallback(reply.isEmpty ? null : reply);
        return;
      }

      _s.liveUsed++;
      _appendAndSettle(PreviewMsg(reply, isUser: false, isLive: true));
      ref.read(posthogServiceProvider).capture(
        eventName: 'coach_preview_live_answered',
        properties: {
          'coach_id': coach.id,
          'turn': _s.liveUsed,
          'final_turn': isFinalTurn,
        },
      );
      if (isFinalTurn) {
        setState(() => _s.capped = true);
        widget.onCapped?.call();
      }
    } catch (_) {
      if (!mounted || token != _s.flightToken) return;
      _handleFallback(null);
    }
  }

  /// Visible degradation: labeled note + a curated answer, then the live
  /// input retires for THIS coach only. Chips keep working.
  void _handleFallback(String? serverReply) {
    final curated = serverReply ?? _chips[1].answer;
    setState(() {
      _s.retired = true;
      _s.typing = false;
      _s.messages.add(PreviewMsg(
        curated,
        isUser: false,
        noteAbove: _content.fallbackLabel,
      ));
    });
    ref.read(posthogServiceProvider).capture(
      eventName: 'coach_preview_fallback',
      properties: {'coach_id': widget.coach.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cc = widget.coach.primaryColor;

    // Adaptive: chips yield first when the card is squeezed (keyboard open
    // on short screens), then the status line under the input. Only the
    // transcript is flexible, so the column can never stripe-overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final showChips = constraints.maxHeight >= 230;
        final showStatus = constraints.maxHeight >= 170;
        return Column(
          children: [
            Expanded(child: _buildTranscript(isDark, textPrimary, cc)),
            if (showChips) _buildChipRow(cc),
            if (widget.liveEnabled)
              _buildLiveRow(isDark, textSecondary, cc, showStatus: showStatus),
          ],
        );
      },
    );
  }

  Widget _buildTranscript(bool isDark, Color textPrimary, Color cc) {
    // reverse:true anchors sparse conversations to the bottom and keeps the
    // newest message in view without manual scroll bookkeeping.
    final items = _s.messages.reversed.toList();
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      itemCount: items.length + (_s.typing ? 1 : 0),
      itemBuilder: (context, index) {
        if (_s.typing && index == 0) return _typingBubble(isDark, cc);
        final msg = items[index - (_s.typing ? 1 : 0)];
        return _bubble(msg, isDark, textPrimary, cc);
      },
    );
  }

  Widget _bubble(PreviewMsg msg, bool isDark, Color textPrimary, Color cc) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: msg.isUser
            ? cc.withValues(alpha: isDark ? 0.35 : 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(15),
          topRight: const Radius.circular(15),
          bottomLeft: Radius.circular(msg.isUser ? 15 : 4),
          bottomRight: Radius.circular(msg.isUser ? 4 : 15),
        ),
        border: msg.isLive
            ? Border.all(color: cc.withValues(alpha: 0.45))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (msg.isLive)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'LIVE ANSWER',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: cc,
                ),
              ),
            ),
          Text(
            msg.text,
            style: TextStyle(fontSize: 12, height: 1.25, color: textPrimary),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment:
          msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (msg.noteAbove != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 4),
            child: Text(
              msg.noteAbove!,
              style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: cc.withValues(alpha: 0.9),
              ),
            ),
          ),
        Align(
          alignment: msg.isUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: bubble,
        ),
      ],
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.06);
  }

  Widget _typingBubble(bool isDark, Color cc) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cc.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 0.5,
                  end: 1.0,
                  delay: Duration(milliseconds: i * 180),
                  duration: 380.ms,
                  curve: Curves.easeInOut,
                );
          }),
        ),
      ),
    );
  }

  Widget _buildChipRow(Color cc) {
    final chips = _chips;
    final remaining = <Widget>[];
    for (var i = 0; i < chips.length; i++) {
      if (_s.askedChips.contains(i)) continue;
      final chip = chips[i];
      remaining.add(Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _askChip(i, chip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cc.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chip.personalized)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.auto_awesome, size: 12, color: cc),
                  ),
                Text(
                  chip.question,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cc,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    if (remaining.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: remaining,
      ),
    );
  }

  Widget _buildLiveRow(bool isDark, Color textSecondary, Color cc,
      {bool showStatus = true}) {
    final disabled = _s.retired || _s.capped;
    final statusText = _s.retired
        ? 'Live chat unavailable — curated answers shown instead'
        : _s.capped
            ? '${widget.coach.name} is ready to start — hit the button below'
            : '${_maxLiveTurns - _s.liveUsed} live question'
                '${_maxLiveTurns - _s.liveUsed == 1 ? '' : 's'} left — '
                'answered by your real coach';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !disabled,
                  maxLength: _maxQuestionChars,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendLive(),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: 'Message ${widget.coach.name}…',
                    hintStyle:
                        TextStyle(fontSize: 13, color: textSecondary),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: cc, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: disabled ? null : _sendLive,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cc.withValues(alpha: disabled ? 0.3 : 1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          if (showStatus) ...[
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(fontSize: 10, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
