/// Get Started Challenge — new-user onboarding checklist (was F3.1 Setup
/// Checklist). A collapsible, gamified card that walks a brand-new user to
/// their first value ("complete your first workout" = the aha) and rewards XP
/// for each step, plus a finish bonus + reward crate on full completion.
///
/// Shown below the Next Workout hero while the user is in their first 14 days
/// and hasn't finished (or dismissed) the challenge. Persistent inline card —
/// NOT a transient notification banner. Collapsed by default (one line: ring +
/// title + "N of M done"); tap the header to expand the task rows.
///
/// Completion is derived from live providers (zero-cost: goal/plan/workout) and
/// the authoritative server claimed-state from `getAvailableFirstTimeBonuses()`
/// (meal/chat, which their own flows award). The card itself CLAIMS the
/// onboarding-specific keys (goal/plan/workout) when it detects them complete —
/// awards are idempotent server-side, so this is safe even if a flow also
/// awarded them. When all items are done it calls `completeOnboardingChallenge()`
/// for the +100 XP finish bonus and a reward crate.
///
/// There used to be a sixth "Pick a program (or let AI decide)" item, removed
/// 2026-08 — onboarding assigns the user an AI-generated workout PLAN (which
/// already satisfies "Generate your first workout plan"), never a curated
/// PROGRAM LIBRARY assignment (`user_program_assignments`), so that item's
/// `done` state depended entirely on the user tapping this exact row (a local
/// `_programSeen` engagement claim) or separately assigning a real program —
/// neither of which normal onboarding triggers. In practice it sat unchecked
/// for most users, stalling the ring at 5/6 forever.
///
/// At 100% the card collapses to a one-line trophy ("All N done · +XP") for
/// [_kTrophyWindowDays] days (persisted as a completion timestamp, so the
/// window survives app restarts), then disappears from Home for good.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/root_messenger.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// How long after signup the challenge stays offered.
const int _kChallengeWindowDays = 14;

/// How long a completed challenge stays visible as a one-line trophy before
/// vanishing from Home for good.
const int _kTrophyWindowDays = 7;

class SetupChecklistCard extends ConsumerStatefulWidget {
  const SetupChecklistCard({super.key});

  @override
  ConsumerState<SetupChecklistCard> createState() =>
      _SetupChecklistCardState();
}

class _SetupChecklistCardState extends ConsumerState<SetupChecklistCard> {
  bool _dismissed = false;
  bool _loaded = false;
  bool _collapsed = true; // collapsed by default — one line until tapped
  bool _done = false; // challenge fully completed (persisted)
  bool _justCompleted = false; // show the celebration this session

  /// When the challenge was completed (persisted as an ISO8601 string), so
  /// the 7-day trophy window survives app restarts. Null if never completed,
  /// or completed before this field existed (treated as expired — see
  /// [build]).
  DateTime? _completedAt;

  /// Authoritative server claimed-state, fetched from
  /// `getAvailableFirstTimeBonuses()` and refreshed while visible.
  final Set<String> _awardedKeys = <String>{};

  /// Bonus keys currently being claimed (prevents duplicate in-flight POSTs).
  final Set<String> _inFlight = <String>{};
  bool _completing = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  String _dismissKey(String uid) => 'get_started_challenge_dismissed_$uid';
  String _collapseKey(String uid) => 'get_started_challenge_collapsed_$uid';
  String _doneKey(String uid) => 'get_started_challenge_done_$uid';
  String _doneAtKey(String uid) => 'get_started_challenge_done_at_$uid';

  Future<void> _init() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      // Dismiss snooze (7-day, JSON like the old card).
      final raw = prefs.getString(_dismissKey(user.id));
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final until =
            DateTime.tryParse(decoded['snoozedUntil'] as String? ?? '');
        if (until != null && until.isAfter(DateTime.now())) _dismissed = true;
      }
      _collapsed = prefs.getBool(_collapseKey(user.id)) ?? true;
      _done = prefs.getBool(_doneKey(user.id)) ?? false;
      if (_done) {
        final doneAtRaw = prefs.getString(_doneAtKey(user.id));
        _completedAt = doneAtRaw != null ? DateTime.tryParse(doneAtRaw) : null;
      }
    } catch (_) {/* ignore */}

    await _refreshAwarded();

    if (mounted) setState(() => _loaded = true);

    // Poll the authoritative claimed-state while the challenge is live so
    // meal/chat completions (awarded by their own flows) are detected without
    // the user re-entering Home. Stops on completion / dismiss / unmount.
    // 60s + offstage skip: the Home branch stays mounted in the shell's
    // IndexedStack, so a naive periodic timer polls even while the user sits
    // on another tab — this endpoint was the single noisiest request in the
    // backend logs (a hit every 20s for the whole session).
    if (!_done && !_dismissed) {
      _poll = Timer.periodic(const Duration(seconds: 60), (_) async {
        if (!mounted || _done) {
          _poll?.cancel();
          return;
        }
        // Offstage IndexedStack branches have tickers disabled — skip the
        // network hit until the user is actually looking at Home.
        if (!TickerMode.of(context)) return;
        await _refreshAwarded();
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _refreshAwarded() async {
    try {
      final repo = ref.read(xpRepositoryProvider);
      final available = await repo.getAvailableFirstTimeBonuses();
      _awardedKeys
        ..clear()
        ..addAll(available.where((b) => b.awarded).map((b) => b.bonusType));
    } catch (_) {/* best-effort */}
  }

  int _daysSinceSignup() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final createdAtRaw = user?.createdAt;
    if (createdAtRaw == null) return 0;
    final parsed = DateTime.tryParse(createdAtRaw);
    if (parsed == null) return 0;
    return DateTime.now().difference(parsed).inDays;
  }

  bool _has(String key) =>
      _awardedKeys.contains(key) ||
      ref.read(xpProvider).awardedBonuses.contains(key);

  bool get _hasAnyMealBonus => _awardedKeys.any((k) =>
      k == 'first_breakfast' ||
      k == 'first_lunch' ||
      k == 'first_dinner' ||
      k == 'first_snack');

  Future<void> _dismissForWeek() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _poll?.cancel();
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _dismissKey(user.id),
        jsonEncode({
          'snoozedUntil':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        }),
      );
    } catch (_) {/* ignore */}
  }

  Future<void> _toggleCollapsed() async {
    HapticService.light();
    final user = ref.read(currentUserProvider).valueOrNull;
    setState(() => _collapsed = !_collapsed);
    if (user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_collapseKey(user.id), _collapsed);
    } catch (_) {/* ignore */}
  }

  /// Claim a single onboarding-specific bonus (idempotent server-side).
  Future<void> _claim(String key) async {
    if (_inFlight.contains(key) || _has(key)) return;
    _inFlight.add(key);
    try {
      await ref.read(xpProvider.notifier).awardFirstTimeBonus(key);
      _awardedKeys.add(key);
    } catch (_) {/* idempotent; ignore */}
    _inFlight.remove(key);
    if (mounted) setState(() {});
  }

  Future<void> _complete() async {
    if (_completing || _has('onboarding_complete')) return;
    _completing = true;
    try {
      final result =
          await ref.read(xpProvider.notifier).completeOnboardingChallenge();
      _awardedKeys.add('onboarding_complete');
      if (mounted) {
        setState(() => _justCompleted = true);
      }
      // Persist done + the completion timestamp, so the 7-day trophy window
      // survives app restarts.
      final user = ref.read(currentUserProvider).valueOrNull;
      final now = DateTime.now();
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_doneKey(user.id), true);
          await prefs.setString(_doneAtKey(user.id), now.toIso8601String());
        } catch (_) {/* ignore */}
      }
      if (mounted) setState(() => _completedAt = now);
      _poll?.cancel();
      if (mounted && result.crateGranted) {
        rootSnackBar(
          SnackBar(
            content: const Text(
                '🎉 Get Started Challenge complete! +100 XP and a reward crate'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => context.push('/rewards'),
            ),
          ),
        );
      }
    } catch (_) {/* ignore */}
    _completing = false;
  }

  /// Claim newly-complete onboarding keys + trigger completion. Runs after the
  /// frame so we never fire network calls during build.
  void _reconcile(List<_Item> items) {
    final pending = <String>[];
    for (final it in items) {
      if (it.claimKey != null && it.done && !_has(it.claimKey!)) {
        pending.add(it.claimKey!);
      }
    }
    final allDone = items.every((i) => i.done);
    if (pending.isEmpty && !(allDone && !_has('onboarding_complete'))) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final k in pending) {
        await _claim(k);
      }
      if (allDone && !_has('onboarding_complete')) await _complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();
    // Finished, celebration already shown → either the 7-day trophy window is
    // still open (collapsed one-liner, handled below) or it's expired (gone
    // for good). A missing timestamp (done before this field existed) is
    // treated as expired rather than resurrecting an old completion.
    final trophyExpired = _completedAt == null ||
        DateTime.now().difference(_completedAt!).inDays >= _kTrophyWindowDays;
    if (_done && !_justCompleted && trophyExpired) {
      return const SizedBox.shrink();
    }
    if (!_done &&
        _daysSinceSignup() > _kChallengeWindowDays &&
        !_justCompleted) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    // ---- Completion signals (live providers + server claimed-state) --------
    final goalDone = (user.targetWeightKg ?? 0) > 0 ||
        user.goalsList.isNotEmpty ||
        _has('first_goal_set');

    bool planDone = _has('first_plan_generated');
    try {
      planDone = planDone ||
          (ref.watch(workoutsProvider).valueOrNull?.isNotEmpty ?? false);
    } catch (_) {/* provider not ready */}

    bool workoutDone = user.lastWorkoutDate != null || _has('first_workout');
    try {
      workoutDone = workoutDone ||
          (ref.watch(todayWorkoutProvider).valueOrNull?.completedToday ??
              false);
    } catch (_) {/* provider not ready */}

    bool mealDone = _hasAnyMealBonus;
    try {
      final n = ref.watch(dailyNutritionProvider(todayNutritionKey()));
      mealDone = mealDone || n.logs.isNotEmpty;
    } catch (_) {/* provider not ready */}

    final chatDone = _has('first_chat');

    final items = <_Item>[
      _Item(
        icon: Icons.flag_rounded,
        label: 'Set your goal',
        xp: 25,
        done: goalDone,
        route: '/profile',
        claimKey: 'first_goal_set',
      ),
      _Item(
        icon: Icons.auto_awesome,
        label: 'Generate your first workout plan',
        xp: 50,
        done: planDone,
        route: '/workouts',
        claimKey: 'first_plan_generated',
      ),
      _Item(
        icon: Icons.fitness_center,
        label: 'Complete your first workout',
        xp: 150,
        done: workoutDone,
        route: '/workouts',
        claimKey: 'first_workout',
      ),
      _Item(
        icon: Icons.restaurant_rounded,
        label: 'Log your first meal',
        xp: 50,
        done: mealDone,
        route: '/nutrition',
        claimKey: null, // awarded by the meal-logging flow
      ),
      _Item(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat with your AI coach',
        xp: 15,
        done: chatDone,
        route: '/chat',
        claimKey: null, // awarded by the chat flow
      ),
    ];

    _reconcile(items);

    final completed = items.where((i) => i.done).length;
    final pct = completed / items.length;

    // Completed, within the 7-day trophy window → a static one-line trophy
    // takes over the whole card, no rows, no accent border (decision: an
    // orange border means something is waiting on you; a finished challenge
    // is information, not a to-do).
    if (_done && !_justCompleted) {
      final totalXp = items.fold<int>(0, (sum, i) => sum + i.xp);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: _buildTrophy(c, items.length, totalXp),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.45)),
      ),
      child: _justCompleted
          ? _buildCelebration(c)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(c, pct, completed, items.length),
                if (!_collapsed) ...[
                  const SizedBox(height: 12),
                  for (final item in items) _buildRow(c, item),
                ],
              ],
            ),
    );
  }

  /// One-line trophy for a completed challenge — ring pinned at 100%, kicker,
  /// and the XP total earned across every item. Tapping opens the reward
  /// crate (same destination as the completion snackbar).
  Widget _buildTrophy(ThemeColors c, int total, int totalXp) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/rewards');
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          _ProgressRing(value: 1.0, accent: c.accent, track: c.cardBorder,
              textColor: c.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GET STARTED CHALLENGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All $total done · +$totalXp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: c.textMuted),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors c, double pct, int completed, int total) {
    return InkWell(
      onTap: _toggleCollapsed,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          _ProgressRing(value: pct, accent: c.accent, track: c.cardBorder,
              textColor: c.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GET STARTED CHALLENGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$completed of $total done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!_collapsed)
            InkWell(
              onTap: _dismissForWeek,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: c.textMuted),
              ),
            ),
          Icon(_collapsed ? Icons.expand_more : Icons.expand_less,
              size: 22, color: c.textMuted),
        ],
      ),
    );
  }

  Widget _buildRow(ThemeColors c, _Item item) {
    return InkWell(
      onTap: item.done ? null : () => context.push(item.route),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            Icon(
              item.done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: item.done ? c.accent : c.textMuted,
            ),
            const SizedBox(width: 10),
            Icon(item.icon, size: 15, color: c.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.done ? c.textMuted : c.textPrimary,
                  decoration: item.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            if (item.xp > 0)
              _XpPill(xp: item.xp, done: item.done, accent: c.accent,
                  muted: c.textMuted, track: c.cardBorder),
            if (!item.done) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration(ThemeColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Challenge complete!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'You earned +100 XP and a reward crate. Nice work getting set up.',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  HapticService.light();
                  context.push('/rewards');
                },
                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                label: const Text('Open your crate'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _justCompleted = false),
              child: Text('Done', style: TextStyle(color: c.textMuted)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final int xp;
  final bool done;
  final String route;

  /// Onboarding-specific bonus key the card claims on detection. Null for
  /// items whose XP is awarded by their own flow (meal/chat).
  final String? claimKey;

  const _Item({
    required this.icon,
    required this.label,
    required this.xp,
    required this.done,
    required this.route,
    required this.claimKey,
  });
}

/// Circular percentage progress ring (matches the reference card).
class _ProgressRing extends StatelessWidget {
  final double value;
  final Color accent;
  final Color track;
  final Color textColor;
  const _ProgressRing(
      {required this.value,
      required this.accent,
      required this.track,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// "+150" style XP reward pill; filled-accent when done.
class _XpPill extends StatelessWidget {
  final int xp;
  final bool done;
  final Color accent;
  final Color muted;
  final Color track;
  const _XpPill(
      {required this.xp,
      required this.done,
      required this.accent,
      required this.muted,
      required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: done ? accent.withValues(alpha: 0.18) : track.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$xp XP',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: done ? accent : muted,
        ),
      ),
    );
  }
}
