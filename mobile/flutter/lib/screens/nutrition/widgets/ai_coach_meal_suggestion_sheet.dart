/// AI-Coach popup anchored on the meal-log sheet.
///
/// State machine: thinking → ready → typing → replied → error/offline.
/// The popup first fetches the lightweight meal-context summary, then
/// renders 3-4 dynamically-chosen preset pills. Tap a pill → sends it
/// through the standard chat endpoint with the full day context already
/// pre-populated in the backend's NutritionAgentState.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/meal_context.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../widgets/glass_sheet.dart';

/// Callbacks the parent provides so the popup can trigger external actions
/// (log a suggested meal, open the full chat) without reaching into
/// unrelated providers.
typedef LogSuggestedFoodCallback = void Function(
    Map<String, dynamic> suggestedFood);
typedef OpenFullChatCallback = void Function({List<ChatMessage>? seededExchange});

enum _CoachPopupState { thinking, ready, typing, replied, error, offline }

class AiCoachMealSuggestionSheet extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? currentWorkout;
  final Map<String, dynamic>? workoutSchedule;
  final String mealType;
  final String timezone;
  final LogSuggestedFoodCallback? onLogSuggestedFood;
  final OpenFullChatCallback? onOpenFullChat;

  const AiCoachMealSuggestionSheet({
    super.key,
    required this.userId,
    required this.mealType,
    required this.timezone,
    this.userProfile,
    this.currentWorkout,
    this.workoutSchedule,
    this.onLogSuggestedFood,
    this.onOpenFullChat,
  });

  @override
  ConsumerState<AiCoachMealSuggestionSheet> createState() =>
      _AiCoachMealSuggestionSheetState();
}

class _AiCoachMealSuggestionSheetState
    extends ConsumerState<AiCoachMealSuggestionSheet>
    with SingleTickerProviderStateMixin {
  _CoachPopupState _state = _CoachPopupState.thinking;
  MealContext? _ctx;
  String? _errorMsg;
  String? _lastSentPrompt;
  String? _lastReplyText;
  Map<String, dynamic>? _lastActionData;
  bool _cancelRequested = false;

  late AnimationController _shimmerCtl;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _shimmerCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadContext();
  }

  @override
  void dispose() {
    _cancelRequested = true;
    _debounceTimer?.cancel();
    _shimmerCtl.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final ctx = await repo.fetchMealContext(
        mealType: widget.mealType,
        timezone: widget.timezone,
      );
      if (!mounted || _cancelRequested) return;
      setState(() {
        _ctx = ctx;
        _state = _CoachPopupState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        // Fall into ready with a null ctx — we'll show generic pills + partial banner
        _ctx = null;
        _state = _CoachPopupState.ready;
      });
    }
  }

  Future<void> _sendPrompt(String prompt) async {
    if (_state == _CoachPopupState.typing) return;
    // Debounce double-taps
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {});

    setState(() {
      _state = _CoachPopupState.typing;
      _lastSentPrompt = prompt;
      _lastReplyText = null;
      _lastActionData = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final resp = await repo.sendMessage(
        message: prompt,
        userId: widget.userId,
        userProfile: widget.userProfile,
        currentWorkout: widget.currentWorkout,
        workoutSchedule: widget.workoutSchedule,
      );
      if (!mounted || _cancelRequested) return;
      setState(() {
        _lastReplyText = resp.message;
        _lastActionData = resp.actionData;
        _state = _CoachPopupState.replied;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Coach is unreachable — try again in a moment.';
        _state = _CoachPopupState.error;
      });
    }
  }

  // ── Pill selection based on context ─────────────────────────────────────

  List<_CoachPill> _buildPills(MealContext? ctx, Color accent) {
    // Prompts deliberately phrased casually ("hit me", "hype me", "quick swap")
    // so the coach's reply picks up the tone. The nutrition agent's CONTEXT
    // block also instructs the LLM to answer punchy + slangy.
    final defaults = <_CoachPill>[
      _CoachPill(
        id: 'what_now',
        label: 'What can I eat now?',
        icon: Icons.restaurant_menu,
        color: accent,
        prompt:
            "Logging my ${widget.mealType}. Hit me with something that fits my day so far — keep it short and real.",
      ),
      _CoachPill(
        id: 'high_protein',
        label: 'High-protein idea?',
        icon: Icons.egg_outlined,
        color: const Color(0xFFF59E0B),
        prompt:
            "I'm hunting for a high-protein ${widget.mealType} option. One pick, macros, and why it's fire.",
      ),
      _CoachPill(
        id: 'quick_snack',
        label: 'Quick snack ideas?',
        icon: Icons.bolt_outlined,
        color: const Color(0xFF06B6D4),
        prompt:
            "Short on time — give me 2–3 quick snack ideas that won't tank my day. Casual tone plz.",
      ),
      _CoachPill(
        id: 'macro_balance',
        label: 'Balance my macros?',
        icon: Icons.pie_chart_outline,
        color: const Color(0xFF8B5CF6),
        prompt:
            "Based on what I've eaten, what macro am I short on and what should I grab to balance it out?",
      ),
    ];

    // Conditionals: promoted FIRST if they apply, else defaults backfill.
    final promoted = <_CoachPill>[];

    if (ctx != null) {
      if (ctx.overBudget) {
        promoted.add(_CoachPill(
          id: 'low_cal',
          label: "Low-cal swap?",
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFEF4444),
          prompt:
              "I'm over budget today. Drop a low-cal swap that still hits the macros I need. Keep it hype.",
        ));
      }
      if (ctx.hasWorkoutToday) {
        final w = ctx.todayWorkout!;
        if (w.isCompleted) {
          promoted.add(_CoachPill(
            id: 'post_workout',
            label: 'Post-workout meal?',
            icon: Icons.fitness_center,
            color: const Color(0xFF10B981),
            prompt:
                "Just finished my ${w.type ?? 'workout'}. Recovery meal that lines up with what I already ate?",
          ));
        } else {
          promoted.add(_CoachPill(
            id: 'pre_workout',
            label: 'Pre-workout fuel?',
            icon: Icons.fitness_center,
            color: const Color(0xFFF59E0B),
            prompt:
                "Got a ${w.type ?? 'workout'} later today. What's a solid pre-workout bite to load up right?",
          ));
        }
      }
      if (ctx.hasFavorites) {
        promoted.add(_CoachPill(
          id: 'favorite',
          label: 'Favorite I missed?',
          icon: Icons.favorite_border,
          color: const Color(0xFFA855F7),
          prompt:
              "Surface one of my favorite meals I haven't had this week and tell me why it fits today.",
        ));
      }
    }

    // Merge: promoted pills first, then defaults excluding anything promoted.
    final promotedIds = promoted.map((p) => p.id).toSet();
    final merged = [
      ...promoted,
      ...defaults.where((d) => !promotedIds.contains(d.id)),
    ];
    return merged.take(4).toList();
  }

  // ── Suggested food extraction ───────────────────────────────────────────

  Map<String, dynamic>? _extractSuggestedFood() {
    final action = _lastActionData;
    if (action == null) return null;
    final suggested = action['suggested_food'];
    if (suggested is! Map) return null;
    // Require macros so we don't log something incomplete.
    final hasMacros = suggested['total_calories'] != null &&
        (suggested['protein_g'] != null ||
            suggested['carbs_g'] != null ||
            suggested['fat_g'] != null);
    if (!hasMacros) return null;
    return Map<String, dynamic>.from(suggested);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final partial = _ctx?.contextPartial == true;

    return GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colors, accent),
            const SizedBox(height: 16),
            if (_state == _CoachPopupState.thinking)
              _buildThinking(colors, accent),
            if (_state == _CoachPopupState.offline)
              _buildOffline(colors),
            if (_state == _CoachPopupState.ready ||
                _state == _CoachPopupState.typing ||
                _state == _CoachPopupState.replied)
              ...[
                if (partial) _buildPartialBanner(colors),
                _buildPillsOrReply(colors, accent),
              ],
            if (_state == _CoachPopupState.error)
              _buildError(colors, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, Color accent) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.85), accent],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Coach',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                _state == _CoachPopupState.thinking
                    ? 'Analyzing your day…'
                    : _state == _CoachPopupState.typing
                        ? 'Coach is typing…'
                        : 'Pick a question or open full chat',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThinking(ThemeColors colors, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerCtl,
            builder: (_, __) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    accent.withValues(alpha: 0.05),
                    accent.withValues(alpha: 0.5),
                    accent.withValues(alpha: 0.05),
                  ],
                  transform: GradientRotation(_shimmerCtl.value * 6.28),
                ),
              ),
              child: Center(
                child: Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Looking at today’s meals, workout, and favorites…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialBanner(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 12, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Working from partial data — answer may be generic.',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillsOrReply(ThemeColors colors, Color accent) {
    final pills = _buildPills(_ctx, accent);
    final children = <Widget>[];
    for (final p in pills) {
      children.add(_buildPill(
        pill: p,
        colors: colors,
        disabled: _state == _CoachPopupState.typing,
        selected: _lastSentPrompt == p.prompt,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: children),
        if (_state == _CoachPopupState.typing)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildTypingRow(colors, accent),
          ),
        if (_state == _CoachPopupState.replied && _lastReplyText != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildReplyCard(_lastReplyText!, colors, accent),
          ),
        const SizedBox(height: 12),
        _buildOpenChatButton(colors, accent),
      ],
    );
  }

  Widget _buildPill({
    required _CoachPill pill,
    required ThemeColors colors,
    required bool disabled,
    required bool selected,
  }) {
    return Material(
      color: selected
          ? pill.color.withValues(alpha: 0.18)
          : pill.color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: disabled ? null : () => _sendPrompt(pill.prompt),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(pill.icon, size: 16, color: pill.color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  pill.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: disabled
                        ? colors.textMuted
                        : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingRow(ThemeColors colors, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CycledStatusText(
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(String replyText, ThemeColors colors, Color accent) {
    final suggested = _extractSuggestedFood();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyText,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colors.textPrimary,
            ),
          ),
          if (suggested != null) ...[
            const SizedBox(height: 12),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  widget.onLogSuggestedFood?.call(suggested);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Log this meal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpenChatButton(ThemeColors colors, Color accent) {
    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Open full chat'),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: () {
        // Snapshot popup exchange so parent can seed the full chat.
        final exchange = <ChatMessage>[];
        if (_lastSentPrompt != null) {
          exchange.add(ChatMessage(
            id: 'popup-user-${DateTime.now().millisecondsSinceEpoch}',
            role: 'user',
            content: _lastSentPrompt!,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
        if (_lastReplyText != null) {
          exchange.add(ChatMessage(
            id: 'popup-ai-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: _lastReplyText!,
            createdAt: DateTime.now().toIso8601String(),
            actionData: _lastActionData,
          ));
        }
        widget.onOpenFullChat?.call(
          seededExchange: exchange.isEmpty ? null : exchange,
        );
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildError(ThemeColors colors, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 10),
          Text(
            _errorMsg ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _state = _CoachPopupState.thinking);
              _loadContext();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOffline(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 32),
          const SizedBox(height: 10),
          Text(
            'Coach needs a connection.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CoachPill {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String prompt;

  const _CoachPill({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.prompt,
  });
}

/// Cycles through coach "thinking" status messages while the reply is
/// pending, so users get a sense that something real is happening instead
/// of staring at one static line. Each message swaps every 2.2s with a
/// soft fade/slide transition.
class _CycledStatusText extends StatefulWidget {
  const _CycledStatusText({this.style});

  final TextStyle? style;

  @override
  State<_CycledStatusText> createState() => _CycledStatusTextState();
}

class _CycledStatusTextState extends State<_CycledStatusText> {
  static const _messages = <String>[
    'Coach is thinking about your day…',
    'Checking your workout history…',
    'Looking at today\u2019s nutrition…',
    'Weighing your macros left…',
    'Factoring in your training load…',
    'Pulling ideas that fit your goals…',
    'Almost there — wrapping up…',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      // Stop on the last line; no point looping "almost there" forever while
      // the backend is still streaming — feels less honest than holding.
      if (_index >= _messages.length - 1) {
        _timer?.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        _messages[_index],
        key: ValueKey<int>(_index),
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
