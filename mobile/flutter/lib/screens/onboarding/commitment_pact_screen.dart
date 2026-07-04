import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/api_client.dart';
import 'pre_auth_quiz_data.dart';
import 'founder_note_sheet.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/hold_to_confirm_button.dart';
import '../../widgets/exercise_image.dart';

import '../../l10n/generated/app_localizations.dart';

/// Commitment Pact Screen — Onboarding v5
///
/// Post-paywall, pre-home. Shows the user's Week 1 schedule and asks them
/// to commit. The commitment-consistency principle (Cialdini): users who
/// publicly commit to a plan have 8-12% higher follow-through. Tapping
/// "I'm in" persists `commitment_pact_accepted=true` to the backend.
class CommitmentPactScreen extends ConsumerStatefulWidget {
  const CommitmentPactScreen({super.key});

  @override
  ConsumerState<CommitmentPactScreen> createState() =>
      _CommitmentPactScreenState();
}

class _CommitmentPactScreenState extends ConsumerState<CommitmentPactScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-warm of today's workout has moved to the router-level auth
    // listener (`_todayWorkoutPrewarmed` in app_router.dart) so that
    // generation kicks off the moment auth completes — not after the
    // paywall — giving the user the full pre-paywall + paywall + commit
    // window of network time before home renders.
  }

  Future<void> _commit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.heavyImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/users/me',
        data: {
          'commitment_pact_accepted': true,
          'commitment_pact_accepted_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Non-fatal — backend mirror is best-effort.
      debugPrint('commitment-pact: backend write failed: $e');
    }

    ref
        .read(posthogServiceProvider)
        .capture(eventName: 'onboarding_commitment_pact_accepted');

    // Onboarding v5.1: post-paid-conversion founder note (Airbnb pattern).
    // Strongest commitment moment in the funnel — they just paid AND
    // committed. The note here lands harder than at first-login. One-time
    // via `seen_founder_note_subscriber`; no-ops if user already saw the
    // new-user trigger.
    if (mounted) {
      await FounderNoteSheet.showAfterConversion(context);
    }

    // Health Connect onboarding next — connect the wearable + capture the
    // health-data consent before the unified permissions primer
    // (this screen → health-connect → permissions-primer → home).
    if (mounted) context.go('/health-connect-onboarding');
  }

  /// First Maybe-later tap → soft-friction confirmation modal.
  /// Recovers the would-skip cohort that's 1 tap away from committing.
  /// BetterMe / Noom A/B data shows ~10–20% of skippers flip to commit
  /// when shown a one-line confirm. Confirmed skips run [_skipCommitment]
  /// which records the negative signal so retention cohorts compare.
  Future<void> _onMaybeLaterTapped() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    ref
        .read(posthogServiceProvider)
        .capture(eventName: 'onboarding_commitment_pact_skip_intent');

    final action = await showGlassSheet<String>(
      context: context,
      builder: (sheetCtx) {
        return GlassSheet(
          opaque: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).commitmentPactSkipTheCommitment,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Members who tap I'm in are 2× more likely to "
                "actually do Week 1. You can still cancel your "
                "trial anytime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(sheetCtx).pop('commit'),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context).commitmentPactIMIn,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop('skip'),
                child: Text(
                  AppLocalizations.of(context).commitmentPactSkipAnyway,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'commit') {
      ref
          .read(posthogServiceProvider)
          .capture(eventName: 'onboarding_commitment_pact_skip_recovered');
      await _commit();
    } else if (action == 'skip') {
      await _skipCommitment();
    }
    // null → user dismissed the sheet (drag-down/back). Stay on screen.
  }

  /// Confirmed skip. Records the negative signal so cohort analysis can
  /// compare D7 retention of acceptors vs skippers, then routes to the
  /// same next-screen the accept path uses.
  Future<void> _skipCommitment() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/users/me',
        data: {
          'commitment_pact_accepted': false,
          'commitment_pact_skipped_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Non-fatal — backend mirror is best-effort. PostHog event below
      // is the primary record.
      debugPrint('commitment-pact: skip backend write failed: $e');
    }

    final quiz = ref.read(preAuthQuizProvider);
    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'onboarding_commitment_pact_skipped',
          properties: <String, Object>{
            'days_per_week': quiz.daysPerWeek ?? 0,
            'training_split': quiz.trainingSplit ?? 'unset',
            'has_goal_weight': quiz.goalWeightKg != null,
          },
        );

    // Health Connect onboarding next — connect the wearable + capture the
    // health-data consent before the unified permissions primer
    // (this screen → health-connect → permissions-primer → home).
    if (mounted) context.go('/health-connect-onboarding');
  }

  /// Compose the personalized commit-pact body — dot strip for the
  /// week, one expanded "first session" card with non-AI data
  /// (duration, muscle groups, equipment derived from quiz answers),
  /// the remaining workout days as compact rows, rest days collapsed
  /// to a single muted pill, and a goal-anchored outcome line. Every
  /// value is computed from `preAuthQuizProvider` state — Gemini
  /// generation is happening in the background but we never read its
  /// output here, so this screen never lies about content that doesn't
  /// exist yet.
  Widget _buildCommitBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final quiz = ref.watch(preAuthQuizProvider);

    // Storage convention: quiz_days_selector.dart emits 0-indexed weekdays
    // (Mon=0..Sun=6, see _dayInfo at quiz_days_selector.dart:34-42). Earlier
    // versions of this file assumed ISO 1-7 indexing, which (a) silently
    // dropped Monday (index 0) at the filter and (b) shifted all surviving
    // labels backwards by one (Thu→Wed, Sat→Fri, etc) — Sentry-tagged user
    // complaint: "I picked Thu/Sat/Sun but the screen shows Wed/Fri/Sat".
    // Now treats input as 0-indexed end-to-end.
    List<int> selected =
        (quiz.workoutDays ?? const <int>[])
            .where((d) => d >= 0 && d <= 6)
            .toList()
          ..sort();
    if (selected.isEmpty) {
      final n = quiz.daysPerWeek ?? 4;
      selected = _defaultDaysFor(n);
    }

    String durationLabel() {
      final mn = quiz.workoutDurationMin;
      final mx = quiz.workoutDurationMax;
      if (mn != null && mx != null && mn != mx) return '$mn–$mx min';
      if (mn != null) return '$mn min';
      if (mx != null) return '$mx min';
      if (quiz.workoutDuration != null) return '${quiz.workoutDuration} min';
      return '45 min';
    }

    final labels = _splitLabels(quiz.trainingSplit, selected.length);
    final equipmentLine = _equipmentSummary(quiz);

    // First session = the user's earliest selected day in the week.
    // Bigger emotional payoff than "Day 1 = always Mon" because it
    // surfaces the actual day they're committing to.
    final firstDay = selected.first;
    final firstLabel = labels[0];

    // Rest of the workout days as compact rows.
    final restWorkoutDays = selected.skip(1).toList();
    final unselectedDays = [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    ].where((d) => !selected.contains(d)).toList();

    const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // The feasibility line is folded into the outcome row's second line
    // (when present) rather than its own block, so the whole body fits one
    // screen without scrolling on common phone heights.
    final feasibility = _feasibilityLine(quiz);

    // Scroll-when-needed: when everything fits (typical 3–4-day plan on a
    // normal phone) this renders exactly like a fixed column and never
    // scrolls; when it doesn't (6–7-day plans, short screens), the WHOLE
    // body scrolls. The previous Flexible-around-the-day-list approach
    // crushed the list into a tiny scroll strip whenever the rest of the
    // content ran tall — a full-height scroll beats a squeezed window.
    // Session map: per-day short labels (UPPER/LOWER/…) under the selected
    // dots, so the week reads as a plan rather than anonymous dots.
    final sessionShortByDay = <int, String>{
      for (var i = 0; i < selected.length; i++)
        selected[i]: _sessionShort(labels[i % labels.length]),
    };

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _WeekDotStrip(
          selectedDays: selected,
          sessionShortByDay: sessionShortByDay,
          firstSessionDay: firstDay,
        ).animate().fadeIn(delay: 380.ms),
        const SizedBox(height: 14),
        _FirstSessionCard(
          dayLabel: dayShort[firstDay].toUpperCase(),
          workoutName: firstLabel,
          duration: durationLabel(),
          muscles: _muscleGroupsFor(firstLabel),
          equipmentLine: equipmentLine,
          exerciseNames: _exercisesFor(firstLabel),
        ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.05),
        if (restWorkoutDays.isNotEmpty || unselectedDays.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
            child: Text(
              AppLocalizations.of(context).commitmentPactOtherWorkoutDays,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: textMuted,
              ),
            ),
          ),
          // One hairline-divided card instead of a stack of separate cards —
          // the rest of the week reads as a single schedule. The page-level
          // scroll handles 6–7-day plans; no inner viewport.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.cardBorder
                    : AppColorsLight.cardBorder,
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < restWorkoutDays.length; i++)
                  _ScheduleRow(
                        dayLabel: dayShort[restWorkoutDays[i]].toUpperCase(),
                        title: labels[(i + 1) % labels.length],
                        trailing: durationLabel(),
                        showDivider: i < restWorkoutDays.length - 1 ||
                            unselectedDays.isNotEmpty,
                      )
                      .animate(delay: (650 + i * 80).ms)
                      .fadeIn()
                      .slideX(begin: 0.04, duration: 300.ms),
                if (unselectedDays.isNotEmpty)
                  _ScheduleRow(
                    icon: Icons.self_improvement_rounded,
                    title: 'Recovery',
                    trailing: unselectedDays
                        .map((d) => dayShort[d].toUpperCase())
                        .join(' · '),
                    muted: true,
                    showDivider: false,
                  ).animate(delay: 1050.ms).fadeIn(),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Outcome banner — the emotional peak. When we have a real weight
        // goal, the delta leads as an Anton stat ("–25 KG") with "this is
        // week 1 of that number"; otherwise it degrades to the plain
        // goal-anchored line.
        Builder(builder: (context) {
          final stat = _bigOutcomeStat(quiz);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.onboardingAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.onboardingAccent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                if (stat != null) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: stat.$1),
                        TextSpan(
                          text: ' ${stat.$2}',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 32,
                      height: 1,
                      color: AppColors.onboardingAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else ...[
                  Icon(
                    Icons.trending_up_rounded,
                    size: 18,
                    color: AppColors.onboardingAccent,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat != null
                            ? 'This is week 1 of that number.'
                            : _outcomeLine(quiz),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: textSecondary,
                        ),
                      ),
                      if (feasibility != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          feasibility,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.04),
        ],
      ),
    );
  }

  /// User's first name, sentence-cased. Falls back to nothing so the
  /// title can collapse gracefully ("Can you commit to week 1?" vs
  /// "Sai, can you commit to week 1?").
  String _firstNameOrEmpty() {
    try {
      final raw = ref.read(preAuthQuizProvider).name?.trim() ?? '';
      if (raw.isEmpty || raw.toLowerCase() == 'user') return '';
      final first = raw.split(RegExp(r'\s+')).first;
      if (first.isEmpty) return '';
      return first[0].toUpperCase() + first.substring(1).toLowerCase();
    } catch (_) {
      return '';
    }
  }

  /// Maps a workout label (Push / Pull / Lower / Full Body / etc.) to
  /// the muscles users actually train on that day. All local — no
  /// dependency on Gemini having generated the actual exercise list.
  List<String> _muscleGroupsFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('push')) return ['Chest', 'Shoulders', 'Triceps'];
    if (l.contains('pull')) return ['Back', 'Biceps', 'Rear Delts'];
    if (l.contains('lower')) return ['Quads', 'Glutes', 'Hamstrings'];
    if (l.contains('chest') && l.contains('back')) {
      return ['Chest', 'Back'];
    }
    if (l.contains('chest')) return ['Chest', 'Triceps'];
    if (l.contains('back')) return ['Back', 'Biceps'];
    if (l.contains('legs')) return ['Quads', 'Glutes', 'Hamstrings'];
    if (l.contains('shoulders') && l.contains('arms')) {
      return ['Shoulders', 'Biceps', 'Triceps'];
    }
    if (l.contains('shoulders')) return ['Shoulders', 'Traps'];
    if (l.contains('arms')) return ['Biceps', 'Triceps'];
    if (l.contains('upper')) {
      return ['Chest', 'Back', 'Shoulders', 'Arms'];
    }
    return ['Total Body'];
  }

  /// Representative exercise names for a workout label, used only to seed
  /// the thumbnail row on the first-session card. These are real
  /// exercise-library display names so `ExerciseImage` resolves an
  /// illustration (no fake AI list — these are the canonical compound lifts
  /// a given split always trains, picked deterministically from the label).
  List<String> _exercisesFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('push')) {
      return ['Bench Press', 'Overhead Press', 'Tricep Pushdown'];
    }
    if (l.contains('pull')) {
      return ['Pull Up', 'Barbell Row', 'Bicep Curl'];
    }
    if (l.contains('lower') || l.contains('legs')) {
      return ['Barbell Squat', 'Romanian Deadlift', 'Leg Press'];
    }
    if (l.contains('chest') && l.contains('back')) {
      return ['Bench Press', 'Barbell Row', 'Lat Pulldown'];
    }
    if (l.contains('chest')) {
      return ['Bench Press', 'Incline Dumbbell Press', 'Tricep Pushdown'];
    }
    if (l.contains('back')) {
      return ['Pull Up', 'Barbell Row', 'Lat Pulldown'];
    }
    if (l.contains('shoulders') && l.contains('arms')) {
      return ['Overhead Press', 'Lateral Raise', 'Bicep Curl'];
    }
    if (l.contains('shoulders')) {
      return ['Overhead Press', 'Lateral Raise', 'Face Pull'];
    }
    if (l.contains('arms')) {
      return ['Bicep Curl', 'Tricep Pushdown', 'Hammer Curl'];
    }
    if (l.contains('upper')) {
      return ['Bench Press', 'Pull Up', 'Overhead Press'];
    }
    // Full Body / Total Body default — one big compound per region.
    return ['Barbell Squat', 'Bench Press', 'Barbell Row'];
  }

  /// Single-line equipment summary derived from quiz state. Combines
  /// `equipment` selections with `workoutEnvironment` to produce
  /// "Dumbbells & Bench at home" or "Full gym access". Falls back to
  /// "Bodyweight" if nothing was selected.
  String _equipmentSummary(PreAuthQuizData quiz) {
    final env = (quiz.workoutEnvironment ?? '').toLowerCase();
    final eq = [
      ...(quiz.equipment ?? const <String>[]),
      ...(quiz.customEquipment ?? const <String>[]),
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String envSuffix = '';
    if (env == 'home') {
      envSuffix = ' at home';
    } else if (env == 'gym') {
      envSuffix = ' at the gym';
    } else if (env == 'outdoor') {
      envSuffix = ' outdoors';
    }

    if (eq.isEmpty) {
      if (env == 'gym') return 'Full gym access';
      return 'Bodyweight$envSuffix';
    }
    // Title-case + show up to 2 items, with "+N more" for the rest.
    String pretty(String s) => s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
    final visible = eq.take(2).map(pretty).toList();
    final extra = eq.length - visible.length;
    final list = extra > 0
        ? '${visible.join(' & ')} +$extra more'
        : visible.join(' & ');
    return '$list$envSuffix';
  }

  /// Outcome anchor line. When we have current + goal weight from the
  /// quiz, surface the delta ("Week 1 of your 12-lb plan"); otherwise
  /// fall back to a still-personalized goal-keyword phrase. Never
  /// references Gemini-generated content.
  /// Short per-day session tag for the week session map (UPPER / LOWER /
  /// PUSH / …). Derived from the same split labels the rows use.
  static String _sessionShort(String label) {
    final l = label.toLowerCase();
    if (l.contains('upper')) return 'UPPER';
    if (l.contains('lower')) return 'LOWER';
    if (l.contains('push')) return 'PUSH';
    if (l.contains('pull')) return 'PULL';
    if (l.contains('leg')) return 'LEGS';
    if (l.contains('full')) return 'FULL';
    if (l.contains('cardio') || l.contains('condition')) return 'CARDIO';
    if (l.contains('core')) return 'CORE';
    final w = label.split(' ').first.toUpperCase();
    return w.length > 6 ? w.substring(0, 6) : w;
  }

  /// The big Anton outcome stat ("–25", "KG") when a real weight goal
  /// exists — mirrors [_outcomeLine]'s math (incl. the lb conversion).
  /// Null for maintenance / missing data so the banner degrades to text.
  (String, String)? _bigOutcomeStat(PreAuthQuizData quiz) {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    if (cur == null || goal == null || cur <= 0 || goal <= 0) return null;
    final delta = (goal - cur).abs();
    if (delta < 0.5) return null;
    final useMetric = quiz.useMetricUnits;
    final amt = useMetric ? delta.round() : (delta * 2.20462).round();
    if (amt <= 0) return null;
    final sign = goal < cur ? '–' : '+';
    return ('$sign$amt', useMetric ? 'KG' : 'LB');
  }

  String _outcomeLine(PreAuthQuizData quiz) {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    final useMetric = quiz.useMetricUnits;
    if (cur != null && goal != null && cur > 0 && goal > 0) {
      final delta = (goal - cur).abs();
      if (delta >= 0.5) {
        final unit = useMetric ? 'kg' : 'lb';
        final amt = useMetric ? delta.round() : (delta * 2.20462).round();
        if (amt > 0) {
          return goal < cur
              ? "Week 1 of your $amt $unit plan."
              : "Week 1 of your $amt $unit gain plan.";
        }
      } else {
        return "Week 1 of your maintenance plan.";
      }
    }
    final g = quiz.goal;
    if (g == 'lose_weight') return 'Week 1 of your weight-loss plan.';
    if (g == 'build_muscle') return 'Week 1 of your muscle-building plan.';
    if (g == 'gain_strength') return 'Week 1 of your strength plan.';
    if (g == 'improve_fitness') return 'Week 1 of your fitness plan.';
    return 'Your first week starts here.';
  }

  /// Feasibility framing (Calorii-audit P6.1) — an *estimated* timeline at a
  /// healthy pace rather than an unsafe "completely achievable in X months"
  /// claim. The quiz stores no weekly-rate/target-date, so we estimate from a
  /// safe default rate (0.75 kg/wk loss · 0.25 kg/wk gain). Returns null when
  /// there's no meaningful delta (maintenance is covered by the outcome line).
  String? _feasibilityLine(PreAuthQuizData quiz) {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    if (cur == null || goal == null || cur <= 0 || goal <= 0) return null;
    final deltaKg = (goal - cur).abs();
    if (deltaKg < 0.5) return null;
    final losing = goal < cur;
    final rateKgPerWeek = losing ? 0.75 : 0.25;
    final weeks = (deltaKg / rateKgPerWeek).ceil();
    if (weeks <= 0) return null;
    return 'Achievable in about $weeks weeks at a healthy pace.';
  }

  /// 0-indexed defaults (Mon=0..Sun=6) — match storage convention from
  /// quiz_days_selector.dart. Previous version returned ISO 1-7 which then
  /// got `- 1`'d everywhere, masking the convention mismatch on the happy
  /// path while breaking when the user explicitly selected Monday.
  List<int> _defaultDaysFor(int n) {
    switch (n) {
      case 1:
        return [2]; // Wed
      case 2:
        return [0, 3]; // Mon, Thu
      case 3:
        return [0, 2, 4]; // Mon, Wed, Fri
      case 4:
        return [0, 1, 3, 4]; // Mon, Tue, Thu, Fri
      case 5:
        return [0, 1, 2, 4, 5]; // Mon-Wed + Fri-Sat
      case 6:
        return [0, 1, 2, 3, 4, 5]; // Mon-Sat
      case 7:
        return [0, 1, 2, 3, 4, 5, 6]; // every day
      default:
        return [0, 2, 4];
    }
  }

  List<String> _splitLabels(String? split, int dayCount) {
    final s = (split ?? '').toLowerCase().replaceAll('-', '_');
    if (s.contains('push_pull_legs') || s == 'ppl') {
      return ['Upper Body Push', 'Upper Body Pull', 'Lower Body'];
    }
    if (s.contains('upper_lower') || s == 'ul') {
      return ['Upper Body', 'Lower Body'];
    }
    if (s.contains('bro') || s == 'body_part') {
      return ['Chest & Triceps', 'Back & Biceps', 'Legs', 'Shoulders', 'Arms'];
    }
    if (s.contains('full_body') || s == 'fullbody' || s == 'fb') {
      return ['Full Body'];
    }
    if (s.contains('arnold')) {
      return ['Chest & Back', 'Shoulders & Arms', 'Legs'];
    }
    if (dayCount <= 2) return ['Full Body'];
    if (dayCount == 3) {
      return ['Upper Body Push', 'Upper Body Pull', 'Lower Body'];
    }
    if (dayCount == 4) return ['Upper Body', 'Lower Body'];
    return ['Upper Body Push', 'Upper Body Pull', 'Lower Body'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).commitmentPactOneLastThing,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              // FittedBox keeps the title on a single line on every device
              // size — the previous fixed 28pt was wrapping "1?" onto a
              // second line on smaller widths, which read amateur. With
              // a first name prefixed, the line is even longer, so the
              // scale-down fallback matters more.
              Builder(
                builder: (_) {
                  final first = _firstNameOrEmpty();
                  final title = first.isEmpty
                      ? 'Can you commit to week 1?'
                      : '$first, can you commit to week 1?';
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      // v7: Anton display caps — the pact reads like a vow.
                      title.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 30,
                        color: textPrimary,
                        height: 1.05,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1);
                },
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).commitmentPactWeLlHandleThe,
                style: TextStyle(fontSize: 15, color: textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Personalized week preview. Composed from quiz answers
              // only — no dependency on Gemini having finished generating
              // the actual session, since that workout call is still in
              // flight when this screen renders.
              Expanded(child: _buildCommitBody()),

              // Pact CTA — a press-and-hold commitment gesture. Holding
              // makes committing feel chosen, not tapped past (and a
              // screen reader gets a plain tap button instead). While the
              // commit request is in flight it shows a spinner.
              (_submitting
                      ? Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.onboardingAccent.withValues(
                                  alpha: 0.6,
                                ),
                                AppColors.onboardingAccent.withValues(
                                  alpha: 0.4,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : HoldToConfirmButton(
                          label: AppLocalizations.of(
                            context,
                          ).commitmentPactHoldToCommit,
                          accessibleLabel: AppLocalizations.of(
                            context,
                          ).commitmentPactIMIn,
                          enabled: !_submitting,
                          onConfirmed: _commit,
                        ))
                  .animate(delay: 1400.ms)
                  .fadeIn()
                  .slideY(begin: 0.1),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _submitting ? null : _onMaybeLaterTapped,
                child: Text(
                  AppLocalizations.of(context).notifsLaterButton,
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal Mon–Sun dot strip. Filled circle = workout, hollow =
/// rest. Today's day gets a thin ring so the user can locate themselves
/// in the week without the rest-day rows from the original layout
/// dominating the page.
/// The week as a SESSION MAP: a connecting rail through the dots, tiny
/// session tags (UPPER / LOWER / …) under the selected days, and a glow ring
/// on the first-session day — the week reads as a plan, not anonymous dots.
class _WeekDotStrip extends StatelessWidget {
  final List<int> selectedDays;
  final Map<int, String> sessionShortByDay;
  final int? firstSessionDay;
  const _WeekDotStrip({
    required this.selectedDays,
    this.sessionShortByDay = const {},
    this.firstSessionDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dotEmpty = (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
        .withValues(alpha: 0.25);
    final railColor = (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
        .withValues(alpha: 0.8);
    // DateTime.weekday is 1..7 (Mon=1..Sun=7). Convert to our 0-indexed
    // convention (Mon=0..Sun=6) to match selectedDays from the quiz.
    final today = DateTime.now().weekday - 1; // 0..6
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Stack(
        children: [
          // Connecting rail behind the dot row (label row is 11px text +
          // 8px gap, so the dots' vertical center sits at ~26px).
          Positioned(
            left: 14,
            right: 14,
            top: 26,
            child: Container(height: 1, color: railColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final dayIdx = i; // 0=Mon, 6=Sun (matches selectedDays)
              final isWorkout = selectedDays.contains(dayIdx);
              final isToday = dayIdx == today;
              final isFirst = dayIdx == firstSessionDay;
              final tag = sessionShortByDay[dayIdx];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    initials[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isToday ? AppColors.onboardingAccent : textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWorkout
                          ? AppColors.onboardingAccent
                          : (isDark
                                ? AppColors.elevated
                                : AppColorsLight.elevated),
                      border: Border.all(
                        color: isWorkout
                            ? AppColors.onboardingAccent
                            : dotEmpty,
                        width: 1.5,
                      ),
                      boxShadow: isFirst
                          ? [
                              BoxShadow(
                                color: AppColors.onboardingAccent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 0,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  SizedBox(height: tag != null ? 5 : 3),
                  // Session tag under selected days; a dot for today keeps
                  // the row height stable without a tag.
                  if (tag != null)
                    Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 7.5,
                        color: AppColors.onboardingAccent,
                      ),
                    )
                  else if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.onboardingAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// One row of the merged "rest of the week" schedule card — day tag (or
/// icon) + session title + right-aligned mono trailing, hairline-divided.
class _ScheduleRow extends StatelessWidget {
  final String? dayLabel;
  final IconData? icon;
  final String title;
  final String trailing;
  final bool muted;
  final bool showDivider;

  const _ScheduleRow({
    this.dayLabel,
    this.icon,
    required this.title,
    required this.trailing,
    this.muted = false,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final divider = (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
        .withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          if (dayLabel != null)
            SizedBox(
              width: 38,
              child: Text(
                dayLabel!,
                style: const TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.onboardingAccent,
                ),
              ),
            )
          else if (icon != null)
            SizedBox(
              width: 38,
              child: Icon(icon, size: 15, color: textMuted),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                color: muted ? textMuted : textPrimary,
              ),
            ),
          ),
          Text(
            trailing.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 10,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The expanded "first session" preview — the user's earliest selected
/// workout day, rendered with the data we know is real BEFORE Gemini
/// finishes (duration range, target muscle groups derived from the
/// chosen split, equipment summary). No fake AI numbers.
class _FirstSessionCard extends StatelessWidget {
  final String dayLabel; // "MON" / "WED" — already uppercased
  final String workoutName; // "Upper Body Push"
  final String duration; // "45–60 min"
  final List<String> muscles; // ["Chest", "Shoulders", "Triceps"]
  final String equipmentLine; // "Dumbbells & Bench at home"
  final List<String> exerciseNames; // ["Bench Press", "Overhead Press", ...]

  const _FirstSessionCard({
    required this.dayLabel,
    required this.workoutName,
    required this.duration,
    required this.muscles,
    required this.equipmentLine,
    required this.exerciseNames,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    // Up to 4 representative thumbnails for the session's compound lifts.
    final thumbs = exerciseNames.take(4).toList();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.onboardingAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onboardingAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onboardingAccent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Accent side-rail marks the hero of the schedule.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.onboardingAccent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 16, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onboardingAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.commitmentPactScreenFirstSession(dayLabel),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Duration as telemetry, not another icon row.
                        Text(
                          duration.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Space Mono',
                            fontSize: 10.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Workout name + a row of exercise thumbnails.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            workoutName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (thumbs.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < thumbs.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: i == 0 ? 0 : 6,
                                  ),
                                  child: ExerciseImage(
                                    exerciseName: thumbs[i],
                                    width: 44,
                                    height: 44,
                                    borderRadius: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 9),
                    // Muscles as chips — scannable, not a text run.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in muscles)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.onboardingAccent.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              m.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Barlow Condensed',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    _CardMetaRow(
                      icon: Icons.inventory_2_outlined,
                      text: equipmentLine,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _CardMetaRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
