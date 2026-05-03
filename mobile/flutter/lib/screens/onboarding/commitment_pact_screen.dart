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

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_commitment_pact_accepted',
        );

    // Onboarding v5.1: post-paid-conversion founder note (Airbnb pattern).
    // Strongest commitment moment in the funnel — they just paid AND
    // committed. The note here lands harder than at first-login. One-time
    // via `seen_founder_note_subscriber`; no-ops if user already saw the
    // new-user trigger.
    if (mounted) {
      await FounderNoteSheet.showAfterConversion(context);
    }

    // Unified pre-permission primer (camera + photos + microphone +
    // notifications). Replaces the previous chain that went
    // notifications-prime → home → permissions-primer → notifications-prime
    // and showed users the notification screen twice.
    if (mounted) context.go('/permissions-primer');
  }

  /// First Maybe-later tap → soft-friction confirmation modal.
  /// Recovers the would-skip cohort that's 1 tap away from committing.
  /// BetterMe / Noom A/B data shows ~10–20% of skippers flip to commit
  /// when shown a one-line confirm. Confirmed skips run [_skipCommitment]
  /// which records the negative signal so retention cohorts compare.
  Future<void> _onMaybeLaterTapped() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final surface =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_commitment_pact_skip_intent',
        );

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Skip the commitment?',
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
                        colors: [
                          AppColors.onboardingAccent,
                          Color(0xFFFF6B00)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "I'm in",
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
                    'Skip anyway',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'commit') {
      ref.read(posthogServiceProvider).capture(
            eventName: 'onboarding_commitment_pact_skip_recovered',
          );
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
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_commitment_pact_skipped',
      properties: <String, Object>{
        'days_per_week': quiz.daysPerWeek ?? 0,
        'training_split': quiz.trainingSplit ?? 'unset',
        'has_goal_weight': quiz.goalWeightKg != null,
      },
    );

    // Unified pre-permission primer (camera + photos + microphone +
    // notifications). Replaces the previous chain that went
    // notifications-prime → home → permissions-primer → notifications-prime
    // and showed users the notification screen twice.
    if (mounted) context.go('/permissions-primer');
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final quiz = ref.watch(preAuthQuizProvider);

    List<int> selected = (quiz.workoutDays ?? const <int>[])
        .where((d) => d >= 1 && d <= 7)
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
    final unselectedDays =
        [1, 2, 3, 4, 5, 6, 7].where((d) => !selected.contains(d)).toList();

    const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeekDotStrip(selectedDays: selected)
              .animate()
              .fadeIn(delay: 380.ms),
          const SizedBox(height: 18),
          _FirstSessionCard(
            dayLabel: dayShort[firstDay - 1].toUpperCase(),
            workoutName: firstLabel,
            duration: durationLabel(),
            muscles: _muscleGroupsFor(firstLabel),
            equipmentLine: equipmentLine,
          ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.05),
          if (restWorkoutDays.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'OTHER WORKOUT DAYS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: textMuted,
                ),
              ),
            ),
            ...restWorkoutDays.asMap().entries.map((entry) {
              final i = entry.key;
              final isoDay = entry.value;
              final label = labels[(i + 1) % labels.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OtherDayRow(
                  day: dayShort[isoDay - 1],
                  label: label,
                  duration: durationLabel(),
                ).animate(delay: (650 + i * 100).ms).fadeIn().slideX(
                      begin: 0.04,
                      duration: 320.ms,
                    ),
              );
            }),
          ],
          if (unselectedDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            _RestPill(
              days: unselectedDays.map((d) => dayShort[d - 1]).toList(),
            ).animate(delay: 1050.ms).fadeIn().slideY(begin: 0.05),
          ],
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.onboardingAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.onboardingAccent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 18, color: AppColors.onboardingAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _outcomeLine(quiz),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.04),
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
    String pretty(String s) =>
        s.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
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
  String _outcomeLine(PreAuthQuizData quiz) {
    final cur = quiz.weightKg;
    final goal = quiz.goalWeightKg;
    final useMetric = quiz.useMetricUnits;
    if (cur != null && goal != null && cur > 0 && goal > 0) {
      final delta = (goal - cur).abs();
      if (delta >= 0.5) {
        final unit = useMetric ? 'kg' : 'lb';
        final amt =
            useMetric ? delta.round() : (delta * 2.20462).round();
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

  List<int> _defaultDaysFor(int n) {
    switch (n) {
      case 1:
        return [3];
      case 2:
        return [1, 4];
      case 3:
        return [1, 3, 5];
      case 4:
        return [1, 2, 4, 5];
      case 5:
        return [1, 2, 3, 5, 6];
      case 6:
        return [1, 2, 3, 4, 5, 6];
      case 7:
        return [1, 2, 3, 4, 5, 6, 7];
      default:
        return [1, 3, 5];
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'One last thing.',
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
              Builder(builder: (_) {
                final first = _firstNameOrEmpty();
                final title = first.isEmpty
                    ? 'Can you commit to week 1?'
                    : '$first, can you commit to week 1?';
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1);
              }),
              const SizedBox(height: 6),
              Text(
                "We'll handle the plan — you handle showing up.",
                style: TextStyle(fontSize: 15, color: textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Personalized week preview. Composed from quiz answers
              // only — no dependency on Gemini having finished generating
              // the actual session, since that workout call is still in
              // flight when this screen renders.
              Expanded(
                child: _buildCommitBody(),
              ),

              // Pact CTA
              GestureDetector(
                onTap: _submitting ? null : _commit,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _submitting
                          ? [
                              AppColors.onboardingAccent.withValues(alpha: 0.6),
                              AppColors.onboardingAccent.withValues(alpha: 0.4),
                            ]
                          : const [
                              AppColors.onboardingAccent,
                              Color(0xFFFF6B00)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.onboardingAccent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "I'm in",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                  ),
                ),
              ).animate(delay: 1400.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _submitting ? null : _onMaybeLaterTapped,
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
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
class _WeekDotStrip extends StatelessWidget {
  final List<int> selectedDays;
  const _WeekDotStrip({required this.selectedDays});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dotEmpty =
        (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
            .withValues(alpha: 0.25);
    final today = DateTime.now().weekday; // 1..7
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final isoDay = i + 1;
          final isWorkout = selectedDays.contains(isoDay);
          final isToday = isoDay == today;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                initials[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isToday
                      ? AppColors.onboardingAccent
                      : textMuted,
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
                      : Colors.transparent,
                  border: Border.all(
                    color: isWorkout
                        ? AppColors.onboardingAccent
                        : dotEmpty,
                    width: 1.5,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          );
        }),
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

  const _FirstSessionCard({
    required this.dayLabel,
    required this.workoutName,
    required this.duration,
    required this.muscles,
    required this.equipmentLine,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.onboardingAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FIRST SESSION · $dayLabel',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workoutName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          _CardMetaRow(
            icon: Icons.schedule_rounded,
            text: duration,
            color: textSecondary,
          ),
          const SizedBox(height: 4),
          _CardMetaRow(
            icon: Icons.fitness_center_rounded,
            text: muscles.join(' · '),
            color: textSecondary,
          ),
          const SizedBox(height: 4),
          _CardMetaRow(
            icon: Icons.inventory_2_outlined,
            text: equipmentLine,
            color: textSecondary,
          ),
        ],
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

/// Compact row for the user's other workout days. Quieter than the
/// expanded "first session" card so the visual hierarchy makes the
/// upcoming day the obvious focal point.
class _OtherDayRow extends StatelessWidget {
  final String day;
  final String label;
  final String duration;
  const _OtherDayRow({
    required this.day,
    required this.label,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.onboardingAccent,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single muted pill listing every rest day. Replaces the old N-row
/// repetition where each rest day got its own card and consumed the
/// same vertical space as a real workout — visual noise that made the
/// page read as 50% recovery.
class _RestPill extends StatelessWidget {
  final List<String> days; // ['Tue','Thu','Sun']
  const _RestPill({required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated)
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.spa_outlined, size: 16, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recovery: ${days.join(' · ')}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

