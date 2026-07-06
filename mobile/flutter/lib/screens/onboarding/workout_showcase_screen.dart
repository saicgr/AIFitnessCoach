import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/providers/demo_tasks_seen_provider.dart';
import 'demo_tasks_screen.dart';
import 'pre_auth_quiz_data.dart';
import 'widgets/demo_intro_splash.dart';
import '../../widgets/glass_sheet.dart';
import '../../l10n/generated/app_localizations.dart';

/// Workout Showcase — Onboarding v5
///
/// 4-frame user-paced tap-through. Renders mockup that visually MATCHES
/// the real active-workout screen (MacroFactor-2026 layout: thumbnail
/// strip + action chips + set tracking table). Real production widgets
/// are not used here because their input dependencies (controllers,
/// providers, RIR state) require user authentication and full workout
/// state — this is a pre-signup demo.
///
/// Each frame has an AI annotation overlay explaining what the user is
/// seeing, plus a persistent skip link in the corner.
class WorkoutShowcaseScreen extends ConsumerStatefulWidget {
  const WorkoutShowcaseScreen({super.key});

  @override
  ConsumerState<WorkoutShowcaseScreen> createState() =>
      _WorkoutShowcaseScreenState();
}

/// Progression model — 4 patterns the real app supports. Demo only;
/// changes the target weights shown in the set table.
enum _DemoProgression { linear, step, undulating, custom }

extension _DemoProgressionDetails on _DemoProgression {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case _DemoProgression.linear:
        return l10n.workoutShowcaseLinearLabel;
      case _DemoProgression.step:
        return l10n.workoutShowcasePyramidLabel;
      case _DemoProgression.undulating:
        return l10n.workoutShowcaseUndulatingLabel;
      case _DemoProgression.custom:
        return l10n.workoutShowcaseAutoLabel;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case _DemoProgression.linear:
        return l10n.workoutShowcaseLinearDesc;
      case _DemoProgression.step:
        return l10n.workoutShowcasePyramidDesc;
      case _DemoProgression.undulating:
        return l10n.workoutShowcaseUndulatingDesc;
      case _DemoProgression.custom:
        return l10n.workoutShowcaseAutoDesc;
    }
  }

  IconData get icon {
    switch (this) {
      case _DemoProgression.linear:
        return Icons.show_chart_rounded;
      case _DemoProgression.step:
        return Icons.stairs_rounded;
      case _DemoProgression.undulating:
        return Icons.waves_rounded;
      case _DemoProgression.custom:
        return Icons.auto_awesome_rounded;
    }
  }

  /// Target weights (lb) for sets W, 1, 2, 3 under this progression
  /// model. All non-Linear models now ramp UP set-by-set so the demo
  /// shows real progressive overload (heavier load, fewer reps).
  List<int> get targetWeights {
    switch (this) {
      case _DemoProgression.linear:
        return [45, 70, 70, 70];
      case _DemoProgression.step:
        // Pyramid up — +10 lb each working set.
        return [45, 70, 80, 90];
      case _DemoProgression.undulating:
        // Wave: medium-heavy / heavy / back-off.
        return [45, 75, 90, 70];
      case _DemoProgression.custom:
        // Auto / AI-tuned default — progressive overload, classic
        // pyramid-up shape (70 → 80 → 90 lb).
        return [45, 70, 80, 90];
    }
  }

  /// Target reps for sets W, 1, 2, 3. Reps drop as weight goes up so
  /// the deltas look like real progressive overload (more weight,
  /// fewer reps).
  List<int> get targetReps {
    switch (this) {
      case _DemoProgression.linear:
        // Same weight every set → reps can stay roughly steady.
        return [7, 9, 8, 7];
      case _DemoProgression.step:
      case _DemoProgression.custom:
        // Pyramid up → drop reps as load climbs.
        return [7, 9, 7, 5];
      case _DemoProgression.undulating:
        // Wave reps inversely to weight.
        return [7, 8, 5, 9];
    }
  }
}

class _WorkoutShowcaseScreenState
    extends ConsumerState<WorkoutShowcaseScreen> {
  int _frame = 0;

  /// Feel-good intro beat ("Let's start your first workout") shown for
  /// ~2.5s before Frame 0. Auto-dismisses; tap skips it early.
  bool _introSeen = false;

  @override
  void initState() {
    super.initState();
    // v7 auto-route: this screen is now the funnel's demo entry point
    // (weight-projection routes here directly, and the post-auth router
    // backstop lands shortcut sign-ups here). Mark the demo stage seen on
    // landing — mirrors the /demo-tasks hub — so the post-auth router
    // never re-routes the user back through the demo after sign-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      ref.read(demoTasksSeenProvider.notifier).markSeen();
    });
  }
  // Lifted state — preserved across frames so a toggled mode/progression
  // doesn't reset between frame 1 and frame 2.
  // Default to Easy mode — beginners outnumber power users in pre-auth,
  // and Easy is the simpler, more apptaste-friendly first impression.
  // The user can still tap "Advanced" to see the full table.
  bool _advancedMode = false;
  // Per-row checkbox state for Advanced mode. Index 0 = warmup, 1-3 =
  // working sets. Tapping a checkbox toggles. When all 3 working sets
  // are checked, the demo auto-advances to Frame 2 (progression).
  final Set<int> _completedRows = {};
  _DemoProgression _progression = _DemoProgression.custom;

  /// Advanced-mode auto-progression flash — the row whose target just
  /// ramped up after the previous set was checked off. Mirrors Easy
  /// mode's green "weight auto-increased" beat. Token guards stale
  /// clears when rows are checked rapidly.
  int? _advFlashRow;
  int _advFlashToken = 0;

  /// CTA label — verbs change so each tap feels like the natural next
  /// action, not a generic "continue".
  String _ctaLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_frame) {
      case 0:
        return l10n.workoutShowcaseLogAllSets;
      case 1:
        return l10n.workoutShowcaseFinishWorkout;
      case 2:
        return l10n.workoutShowcaseContinue;
      case 3:
      default:
        // Reserve "I'm in" for the canonical commit-pact screen so the
        // commitment moment lands harder. Earlier showcase screens use
        // a quieter "Continue" so the verb doesn't get diluted.
        return l10n.workoutShowcaseContinue;
    }
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_frame < 3) {
      setState(() => _frame++);
      return;
    }
    _markCompleteAndExit();
  }

  /// Toggle a working-set checkbox. Auto-advances to Frame 2
  /// (progression) once all 3 working sets (rows 1, 2, 3) are checked.
  /// Warmup (row 0) is pre-checked visually but not required.
  void _toggleSetRow(int rowIndex) {
    HapticFeedback.selectionClick();
    final wasChecked = _completedRows.contains(rowIndex);
    setState(() {
      if (wasChecked) {
        _completedRows.remove(rowIndex);
      } else {
        _completedRows.add(rowIndex);
      }
    });
    // Checking a working set whose successor ramps up → flash the next
    // row's target green so the auto-progression is visible (Easy-mode
    // parity for the "Zealova progresses you automatically" moment).
    if (!wasChecked && rowIndex >= 1 && rowIndex < 3) {
      final next = rowIndex + 1;
      final w = _progression.targetWeights;
      if (!_completedRows.contains(next) && w[next] > w[rowIndex]) {
        setState(() => _advFlashRow = next);
        ref.read(posthogServiceProvider).capture(
          eventName: 'demo_autoprogress_shown',
          properties: {
            'mode': 'advanced',
            'set': rowIndex,
            'delta_lb': w[next] - w[rowIndex],
          },
        );
        final token = ++_advFlashToken;
        Future.delayed(const Duration(milliseconds: 2600), () {
          if (mounted && token == _advFlashToken) {
            setState(() => _advFlashRow = null);
          }
        });
      }
    }
    // All 3 working sets logged → reveal the progression frame.
    if (_completedRows.containsAll({1, 2, 3})) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _frame == 0) _next();
      });
    }
  }

  Future<void> _markCompleteAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DemoTasksScreen.workoutDoneKey, true);
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_workout_showcase_completed',
        );
    if (!mounted) return;
    // Legacy hub entry (pushed from /demo-tasks) → pop back so the hub
    // shows the DONE badge. Funnel auto-route entry (context.go → no
    // stack) → chain straight into the nutrition demo, keeping one
    // forward rail: workout → nutrition → sign-in.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/demo-nutrition-showcase');
    }
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_workout_showcase_skipped',
          properties: {'frame': _frame},
        );
    if (!mounted) return;
    // Legacy hub entry → pop back to the chooser. Funnel auto-route
    // entry → skip means "no demos", so continue forward to sign-in
    // (push preserves this screen underneath so Back returns here).
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: skip + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textPrimary),
                    onPressed: _skip,
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(4, (i) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: i < 3 ? 3 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _frame
                                  ? AppColors.onboardingAccent
                                  : AppColors.onboardingAccent
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppLocalizations.of(context)!.onboardingSkip,
                      style: const TextStyle(
                        color: AppColors.onboardingAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Frame body. NOTE: previously this wrapped the entire
            // frame in GestureDetector(onTap: _next), which advanced
            // the demo on ANY tap — including chips, table rows, the
            // illustration. Now only the bottom CTA button advances.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: !_introSeen
                    ? DemoIntroSplash(
                        key: const ValueKey('w-intro'),
                        icon: Icons.fitness_center_rounded,
                        accent: AppColors.onboardingAccent,
                        title: AppLocalizations.of(context)
                            .workoutShowcaseIntroTitle,
                        subtitle: AppLocalizations.of(context)
                            .workoutShowcaseIntroSubtitle,
                        onDone: () {
                          if (mounted) setState(() => _introSeen = true);
                        },
                      )
                    : _buildFrame(_frame, isDark),
              ),
            ),

            // ── CTA — hidden on Frame 0 because the user is supposed to
            // actually tap the set checkboxes (real apptaste). Easy mode
            // has its own ✓ Log set button which advances after set 3.
            if (_frame > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
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
                    child: Center(
                      child: Text(
                        _ctaLabel(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrame(int idx, bool isDark) {
    switch (idx) {
      case 0:
        return _Frame1ActiveWorkout(
          key: const ValueKey('f0'),
          isDark: isDark,
          advancedMode: _advancedMode,
          onToggleMode: (v) {
            HapticFeedback.selectionClick();
            setState(() => _advancedMode = v);
          },
          progression: _progression,
          onProgressionPicked: (p) => setState(() => _progression = p),
          completedRows: _completedRows,
          onToggleRow: _toggleSetRow,
          advFlashRow: _advFlashRow,
          onAdvance: _next,
        );
      case 1:
        return _Frame2SetLogged(
          key: const ValueKey('f1'),
          isDark: isDark,
          progression: _progression,
        );
      case 2:
        return _Frame3Complete(key: const ValueKey('f2'), isDark: isDark);
      case 3:
        // Pull the user's first name from the pre-auth quiz so cards
        // like Newspaper can personalize the headline ("SAI lifts ..."
        // instead of "LOCAL HERO ...").
        final fullName = ref.read(preAuthQuizProvider).name?.trim() ?? '';
        final firstName = fullName.isEmpty
            ? null
            : fullName.split(RegExp(r'\s+')).first.toUpperCase();
        return _Frame4Shareable(
          key: const ValueKey('f3'),
          isDark: isDark,
          userFirstName: firstName,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Glass bottom sheet — matches the real `showProgressionSheetImpl()` in
  /// active_workout_screen_refactored.dart, but with hardcoded mock data.
  Future<void> _openProgressionSheet(BuildContext ctx) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final picked = await showGlassSheet<_DemoProgression>(
      context: ctx,
      builder: (sheetCtx) {
        return GlassSheet(
          opaque: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.textSecondary
                                : AppColorsLight.textSecondary)
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(sheetCtx)!.workoutShowcaseProgressionModel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(sheetCtx)!.workoutShowcaseHowYourWeightReps,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._DemoProgression.values.map((p) {
                    final selected = p == _progression;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetCtx).pop(p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.onboardingAccent
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.onboardingAccent
                                  : (isDark
                                      ? AppColors.cardBorder
                                      : AppColorsLight.cardBorder),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.onboardingAccent
                                      .withValues(
                                          alpha: selected ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  p.icon,
                                  color: AppColors.onboardingAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.localizedLabel(AppLocalizations.of(sheetCtx)!),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.textPrimary
                                            : AppColorsLight.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.localizedDescription(AppLocalizations.of(sheetCtx)!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColorsLight.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.onboardingAccent,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _progression = picked);
    }
  }
}

// ── Frame 1: faithful active-workout replica with Easy/Advanced toggle
class _Frame1ActiveWorkout extends StatelessWidget {
  final bool isDark;
  final bool advancedMode;
  final ValueChanged<bool> onToggleMode;
  final _DemoProgression progression;
  final ValueChanged<_DemoProgression> onProgressionPicked;
  final Set<int> completedRows;
  final ValueChanged<int> onToggleRow;
  final int? advFlashRow;
  final VoidCallback onAdvance;

  const _Frame1ActiveWorkout({
    super.key,
    required this.isDark,
    required this.advancedMode,
    required this.onToggleMode,
    required this.progression,
    required this.onProgressionPicked,
    required this.completedRows,
    required this.onToggleRow,
    this.advFlashRow,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return advancedMode
        ? _AdvancedActiveLayout(
            isDark: isDark,
            onToggleMode: onToggleMode,
            progression: progression,
            completedRows: completedRows,
            onToggleRow: onToggleRow,
            advFlashRow: advFlashRow,
            onProgressionTap: () =>
                _findShowcaseState(context)?._openProgressionSheet(context),
          )
        : _EasyActiveLayout(
            isDark: isDark,
            onToggleMode: onToggleMode,
            onAdvance: onAdvance,
            progression: progression,
          );
  }

  _WorkoutShowcaseScreenState? _findShowcaseState(BuildContext ctx) =>
      ctx.findAncestorStateOfType<_WorkoutShowcaseScreenState>();
}

/// Toggle pill — Easy (blue active) / Advanced (white active). Matches
/// the real top-bar segmented control in `workout_top_bar_v2.dart`.
class _ModeToggle extends StatelessWidget {
  final bool advanced;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.advanced, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    final inactive = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Builder(builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seg(l10n.workoutShowcaseEasy, !advanced, () => onChanged(false), inactive),
            _seg(l10n.workoutShowcaseAdvanced, advanced, () => onChanged(true), inactive),
          ],
        );
      }),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap, Color inactiveColor) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : inactiveColor,
          ),
        ),
      ),
    );
  }
}

/// Stylized exercise illustration card — anatomical figure on white square.
/// Until S3 illustrations are bundled locally we use a styled icon to keep
/// the demo zero-network. The real screen uses CachedNetworkImage against
/// `ILLUSTRATIONS ALL/<exercise>.png`.
class _ExerciseIllustrationCard extends StatelessWidget {
  final double size;
  // Real Zealova exercise illustration (downloaded from S3
  // `ILLUSTRATIONS ALL/Legs/Barbell Full Squat_female.jpg`). Pass
  // `assetPath` to swap to a different exercise.
  final String assetPath;
  const _ExerciseIllustrationCard({
    this.size = 120,
    this.assetPath = 'assets/images/exercises/barbell_squat.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.accessibility_new_rounded,
            size: size * 0.65,
            color: const Color(0xFF424242),
          ),
        ),
      ),
    );
  }
}

/// Color-graded RIR (Reps in Reserve) scale — red→green chips 0..5+.
/// Matches the real `RirSelector` pattern in advanced workouts.
class _RirScale extends StatelessWidget {
  const _RirScale();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('0', Color(0xFFEF4444)),
      ('1', Color(0xFFF97316)),
      ('2', Color(0xFFEAB308)),
      ('3', Color(0xFF22C55E)),
      ('4', Color(0xFF16A34A)),
      ('5+', Color(0xFF15803D)),
    ];
    return Row(
      children: [
        const Text(
          'RIR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white60,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        for (final item in items) ...[
          Expanded(
            child: Container(
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: item.$2.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.$2, width: 1),
              ),
              child: Center(
                child: Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: item.$2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Advanced active workout layout — full table, RIR, chips, AI input,
/// thumbnail strip. Modeled on `active_workout_screen_refactored.dart`.
class _AdvancedActiveLayout extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleMode;
  final _DemoProgression progression;
  final VoidCallback onProgressionTap;
  final Set<int> completedRows;
  final ValueChanged<int> onToggleRow;
  final int? advFlashRow;

  const _AdvancedActiveLayout({
    required this.isDark,
    required this.onToggleMode,
    required this.progression,
    required this.onProgressionTap,
    required this.completedRows,
    required this.onToggleRow,
    this.advFlashRow,
  });

  @override
  Widget build(BuildContext context) {
    final targets = progression.targetWeights;
    // Non-scrollable, fits on one screen — matches the real
    // active_workout_screen_refactored.dart which uses fixed positioning.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Top bar: Warmup E badge + toggle + heart + PiP + timer
          Row(
            children: [
              Text(AppLocalizations.of(context)!.workoutShowcaseWarmup,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  )),
              const SizedBox(width: 8),
              _ModeToggle(advanced: true, onChanged: onToggleMode),
              const Spacer(),
              const Icon(Icons.favorite_border_rounded,
                  color: Colors.white54, size: 22),
              const SizedBox(width: 12),
              const Icon(Icons.picture_in_picture_alt_rounded,
                  color: Colors.white54, size: 22),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                '00:21',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          // Stats strip
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Row(
              children: [
                _statPill(l10n.workoutShowcaseDuration, '21s',
                    const Color(0xFF22C55E), isDark),
                const SizedBox(width: 8),
                _statPill(l10n.workoutShowcaseCalories, '3 kcal', null, isDark),
                const SizedBox(width: 8),
                _statPill(l10n.workoutShowcaseVolume, '0 lb', null, isDark),
              ],
            );
          }).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 10),
          // Exercise title + Info chip
          Row(
            children: [
              Text(
                'Barbell Squat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.cardBorder
                        : AppColorsLight.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColorsLight.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.workoutShowcaseInfo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColorsLight.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.workoutShowcaseSet1Of4,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColorsLight.textSecondary,
                ),
              ),
              const Spacer(),
              Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OutlinedChip(
                        icon: Icons.air_rounded, label: l10n.workoutShowcaseBreathing),
                    const SizedBox(width: 8),
                    _OutlinedChip(
                      icon: Icons.skip_next_rounded,
                      label: l10n.onboardingSkip,
                      accent: AppColors.onboardingAccent,
                    ),
                  ],
                );
              }),
            ],
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          // Action chips row
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _OutlinedChip(
                      icon: Icons.tune_rounded, label: l10n.workoutShowcaseAdjust),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onProgressionTap,
                    child: _OutlinedChip(
                      icon: progression.icon,
                      label: progression.localizedLabel(l10n),
                      accent: AppColors.onboardingAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OutlinedChip(
                      icon: Icons.compare_arrows_rounded,
                      label: l10n.workoutShowcaseSuperset),
                  const SizedBox(width: 8),
                  _OutlinedChip(
                      icon: Icons.swap_horiz_rounded, label: l10n.workoutShowcaseLR),
                ],
              ),
            );
          }).animate(delay: 280.ms).fadeIn(),
          const SizedBox(height: 8),
          // Set tracking table — renders at natural height (no internal
          // scroll). All 4 sets + RIR scale always visible at once.
          _AdvancedSetTable(
            isDark: isDark,
            targetWeights: targets,
            progression: progression,
            completedRows: [
              true, // warmup pre-completed visually
              completedRows.contains(1),
              completedRows.contains(2),
              completedRows.contains(3),
            ],
            onToggleRow: onToggleRow,
            flashRow: advFlashRow,
          ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.04),
          const SizedBox(height: 6),
          // Exercise thumbnail strip — real Zealova illustrations from
          // S3 `ILLUSTRATIONS ALL/`. Active first thumb has orange border.
          // Replaces the bar-config decoration (less informative for the
          // demo than seeing the actual workout sequence).
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                const thumbs = [
                  'assets/images/exercises/barbell_squat.jpg',
                  'assets/images/exercises/bench_press.jpg',
                  'assets/images/exercises/lat_pulldown.jpg',
                  'assets/images/exercises/cable_row.jpg',
                  'assets/images/exercises/overhead_press.jpg',
                ];
                return _exerciseThumb(thumbs[i], isActive: i == 0);
              },
            ),
          ).animate(delay: 420.ms).fadeIn(),
          // Bottom action chips (pinned)
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Row(
              children: [
                _toastChip(
                  ctx,
                  icon: Icons.menu_book_rounded,
                  label: l10n.workoutShowcaseInstructions,
                  accent: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                _toastChip(
                  ctx,
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.workoutShowcaseVideo,
                  accent: const Color(0xFFA855F7),
                ),
                const SizedBox(width: 8),
                _toastChip(
                  ctx,
                  icon: Icons.water_drop_outlined,
                  label: l10n.workoutShowcaseLogDrink,
                  accent: const Color(0xFF06B6D4),
                ),
              ],
            );
          }).animate(delay: 480.ms).fadeIn(),
          // Push the footer to the bottom — fills the dead space that
          // appeared after we hid the global "Tap to continue" CTA on
          // Frame 0.
          const Spacer(),
          // Up next + Ask coach footer — matches Easy mode + the
          // production active-workout footer pattern. Gives the demo
          // a familiar finish and gets rid of the empty void below.
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.elevated
                        : AppColorsLight.elevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/exercises/bench_press.jpg',
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.accessibility_new_rounded,
                            size: 18,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.workoutShowcaseUpNextBenchPress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColorsLight.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.skip_next_rounded,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColorsLight.textSecondary,
                          size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.orange, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.workoutShowcaseAskCoach,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate(delay: 540.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _statPill(
      String label, String value, Color? indicator, bool isDark) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (indicator != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: indicator,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseThumb(String assetPath, {required bool isActive}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.orange : Colors.black12,
          width: isActive ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.accessibility_new_rounded,
            size: 28,
            color: Color(0xFF424242),
          ),
        ),
      ),
    );
  }

  /// Tap chip — haptic-only, no toast.
  Widget _toastChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: _OutlinedChip(icon: icon, label: label, accent: accent),
    );
  }
}

/// Easy mode active layout — focal column, big steppers.
/// Easy mode — stateful, fully interactive, non-scrolling.
/// Steppers actually update weight/reps. Unit toggle works. Action
/// chips (Video / Instructions / Plan / Note) toast on tap. Log set
/// confirms via toast.
class _EasyActiveLayout extends ConsumerStatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onAdvance;
  final _DemoProgression progression;
  const _EasyActiveLayout({
    required this.isDark,
    required this.onToggleMode,
    required this.onAdvance,
    required this.progression,
  });

  @override
  ConsumerState<_EasyActiveLayout> createState() =>
      _EasyActiveLayoutState();
}

class _EasyActiveLayoutState extends ConsumerState<_EasyActiveLayout> {
  // Default to LB — `_DemoProgression.targetWeights` stores raw pound
  // values (70 / 80 / 90 lb etc., matching the Advanced table). If we
  // showed those as kg by default we'd be lying about the load
  // (70 kg ≈ 154 lb is not what the demo is depicting).
  bool _useKg = false;

  /// Per-set reps pulled from the active progression model. Drops
  /// alongside increasing weight so the user sees real progressive
  /// overload (more weight, fewer reps).
  List<int> get _setReps {
    final all = widget.progression.targetReps; // [warmup, set1, set2, set3]
    return [all[1], all[2], all[3]];
  }
  // 0 = "Set 1 ready", 1 = "Set 2 ready", 2 = "Set 3 ready", 3 = all done.
  // Tapping "✓ Log set" advances the counter; reaching 3 fires onAdvance.
  int _setsLogged = 0;
  // Live values shown in the steppers — pre-filled with the active
  // progression's target for the current working set in the user's
  // chosen unit. ± steppers and unit toggle mutate this directly.
  late double _weight = _targetWeightInCurrentUnit(0);
  late int _reps = _setReps[0];

  /// Target weight in lb for working-set index `i` (0/1/2) per the
  /// active progression model. The underlying values in
  /// `_DemoProgression.targetWeights` are stored as pounds, so this
  /// returns lb directly.
  int _targetWeightLbFor(int workingSetIndex) {
    final list = widget.progression.targetWeights;
    return list[(workingSetIndex + 1).clamp(0, list.length - 1)];
  }

  /// Same target, converted into the user's currently-selected unit so
  /// the steppers always display values that match the unit chip.
  double _targetWeightInCurrentUnit(int workingSetIndex) {
    final lb = _targetWeightLbFor(workingSetIndex).toDouble();
    return _useKg ? lb / 2.20462 : lb;
  }

  /// On every set logged, prefill the steppers with the NEXT set's
  /// target weight + reps so the user sees the progression in action.
  /// Honors the current unit (lb or kg) so a user toggled to kg sees
  /// kg values, not raw lb numbers.
  void _advanceToNextSetTargets() {
    if (_setsLogged >= 3) return;
    setState(() {
      _weight = _targetWeightInCurrentUnit(_setsLogged);
      _reps = _setReps[_setsLogged.clamp(0, 2)];
    });
  }

  static const _accent = Color(0xFF38BDF8);
  static const _progressGreen = Color(0xFF22C55E);

  /// "Weight auto-increased" flash — set when logging a set auto-raises
  /// the next target load, so the user SEES progressive overload happen
  /// instead of the steppers changing silently. Cleared after a short
  /// beat (token guards stale timers when sets are logged rapidly).
  String? _autoProgressMsg;
  int _autoProgressToken = 0;

  // Haptic-only tap confirmation — no toast.
  void _toast(String msg) {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Scrollable so the fixed-height column can never stripe-overflow on
    // short screens — it's height-exact on many devices, and a few px of
    // copy or padding drift kept tripping the 1px RenderFlex overflow.
    // No flex children inside, so when content fits this is identical to
    // the plain Column.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 4),
          // No mock back arrow: it was dead chrome duplicating the demo's
          // own X right above it, and read as a broken button.
          Center(
            child: _ModeToggle(advanced: false, onChanged: widget.onToggleMode),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(l10n.workoutShowcaseDuration, '46s', textPrimary, textSecondary),
                _stat(l10n.workoutShowcaseCalories, '6 kcal', textPrimary, textSecondary),
                _stat(l10n.workoutShowcaseVolume, '0 lb', textPrimary, textSecondary),
              ],
            );
          }).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Barbell Squat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 4),
          // Set label — tracks which working set the user is currently
          // logging (1 → 2 → 3 → done).
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Text(
              _setsLogged >= 3
                  ? l10n.workoutShowcaseAll3SetsDone
                  : l10n.workoutShowcaseSetNOf3(_setsLogged + 1),
              style: TextStyle(fontSize: 13, color: textSecondary),
            );
          }).animate(delay: 180.ms).fadeIn(),
          const SizedBox(height: 8),
          const _ExerciseIllustrationCard(size: 110)
              .animate(delay: 220.ms)
              .fadeIn()
              .scale(begin: const Offset(0.92, 0.92)),
          const SizedBox(height: 8),
          // Sub action row — tap-to-toast
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(Icons.play_circle_outline_rounded, l10n.workoutShowcaseVideo,
                    textPrimary, () => _toast('Demo videos play here.')),
                _action(Icons.menu_book_rounded, l10n.workoutShowcaseInstructions,
                    textPrimary, () => _toast('Step-by-step form cues.')),
                _action(Icons.list_alt_rounded, l10n.workoutShowcasePlan, textPrimary,
                    () => _toast('Your full plan for the week.')),
                _action(Icons.edit_note_rounded, l10n.workoutShowcaseNote, textPrimary,
                    () => _toast('Add a note to this set.')),
              ],
            );
          }).animate(delay: 280.ms).fadeIn(),
          const SizedBox(height: 8),
          // Progress dots — reflect the live `_setsLogged` counter so
          // the user can see set 1 / set 2 / set 3 marching forward.
          Builder(builder: (_) {
            Color colorFor(int idx) {
              if (idx < _setsLogged) return textSecondary;
              if (idx == _setsLogged) return textPrimary;
              return textSecondary.withValues(alpha: 0.5);
            }

            FontWeight weightFor(int idx) =>
                idx == _setsLogged ? FontWeight.w800 : FontWeight.w500;

            String labelFor(int idx) {
              if (idx < _setsLogged) {
                final target = _targetWeightInCurrentUnit(idx);
                final str = target == target.roundToDouble()
                    ? target.toStringAsFixed(0)
                    : target.toStringAsFixed(1);
                return 'Set ${idx + 1} ✓ $str${_useKg ? "kg" : "lb"}';
              }
              if (idx == _setsLogged) return 'Set ${idx + 1} now';
              return 'Set ${idx + 1}';
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0)
                    Text(' · ',
                        style: TextStyle(color: textSecondary)),
                  Text(
                    labelFor(i),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: weightFor(i),
                      color: colorFor(i),
                    ),
                  ),
                ],
              ],
            );
          }).animate(delay: 320.ms).fadeIn(),
          const SizedBox(height: 10),
          _stepper(
            label: AppLocalizations.of(context)!.workoutShowcaseWeight,
            value: _weight.toStringAsFixed(_weight == _weight.roundToDouble() ? 0 : 1),
            unit: _useKg ? 'kg' : 'lb',
            showUnitToggle: true,
            highlightValue: _autoProgressMsg != null,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onMinus: () => setState(() {
              HapticFeedback.selectionClick();
              final step = _useKg ? 2.5 : 5.0;
              _weight = (_weight - step).clamp(0, 999);
            }),
            onPlus: () => setState(() {
              HapticFeedback.selectionClick();
              final step = _useKg ? 2.5 : 5.0;
              _weight = (_weight + step).clamp(0, 999);
            }),
          ).animate(delay: 360.ms).fadeIn(),
          const SizedBox(height: 8),
          _stepper(
            label: AppLocalizations.of(context)!.workoutShowcaseReps,
            value: '$_reps',
            unit: 'reps',
            showUnitToggle: false,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onMinus: () => setState(() {
              HapticFeedback.selectionClick();
              if (_reps > 0) _reps--;
            }),
            onPlus: () => setState(() {
              HapticFeedback.selectionClick();
              _reps++;
            }),
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 10),
          // Tooltip + arrow pointing at the Log set button. Mirrors the
          // nutrition demo's menu-scan indicator so the user knows where
          // to tap. Hidden once all 3 sets are logged. While the
          // auto-progression flash is live it takes over this slot (same
          // height, so the fixed column never overflows).
          if (_setsLogged < 3 && _autoProgressMsg != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // No arrow here — this slot sits under the REPS stepper,
                  // so an up-arrow read as "reps increased". The green ↑
                  // now renders inline next to the weight value itself
                  // (see _stepper's highlightValue).
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _progressGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _progressGreen.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          _autoProgressMsg!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            )
          else if (_setsLogged < 3)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.workoutShowcaseTapToLogSet(_setsLogged + 1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -3, duration: 800.ms),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 18,
                    color: _accent,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: 4, duration: 800.ms),
                ],
              ),
            ),
          const SizedBox(height: 4),
          // Log set button — advances the per-set counter on each tap;
          // reaching 3 logged sets auto-advances the demo to Frame 2.
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              final unit = _useKg ? 'kg' : 'lb';
              setState(() => _setsLogged++);
              if (_setsLogged >= 3) {
                _toast('All 3 sets logged. Nice work!');
                Future.delayed(const Duration(milliseconds: 400),
                    widget.onAdvance);
              } else {
                _toast(
                    'Set $_setsLogged logged: $_weight $unit × $_reps reps. Resting…');
                // Advance the steppers to the NEXT set's progression
                // target so the user sees the weight/reps actually
                // change (Linear: same; Step: stair; Undulating: wave).
                final prevWeight = _weight;
                _advanceToNextSetTargets();
                // Make the auto-bump explicit — this is the "Zealova
                // progresses you automatically" teaching moment.
                final delta = _weight - prevWeight;
                if (delta > 0) {
                  final d = delta == delta.roundToDouble()
                      ? delta.toStringAsFixed(0)
                      : delta.toStringAsFixed(1);
                  setState(() => _autoProgressMsg =
                      AppLocalizations.of(context)
                          .workoutShowcaseAutoProgressFlash(d, unit));
                  ref.read(posthogServiceProvider).capture(
                    eventName: 'demo_autoprogress_shown',
                    properties: {
                      'mode': 'easy',
                      'set': _setsLogged,
                      'delta': d,
                      'unit': unit,
                    },
                  );
                  final token = ++_autoProgressToken;
                  Future.delayed(const Duration(milliseconds: 3000), () {
                    if (mounted && token == _autoProgressToken) {
                      setState(() => _autoProgressMsg = null);
                    }
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Text(
                    _setsLogged >= 3
                        ? l10n.workoutShowcaseAllSetsLogged
                        : l10n.workoutShowcaseLogSet(_setsLogged + 1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ).animate(delay: 440.ms).fadeIn(),
          const SizedBox(height: 8),
          // Log water reminder — quick chip for hydration logging.
          GestureDetector(
            onTap: () => _toast(
                'Water logged · 250 ml. Hydration matters mid-workout.'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        const Color(0xFF06B6D4).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF06B6D4), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.workoutShowcaseLogWater,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 480.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _stat(
      String label, String value, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary)),
      ],
    );
  }

  Widget _action(
      IconData icon, String label, Color textPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: textPrimary, size: 18),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _stepper({
    required String label,
    required String value,
    required String unit,
    required bool showUnitToggle,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    bool highlightValue = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                )),
            const Spacer(),
            if (showUnitToggle) _unitToggle(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stepperBtn(Icons.remove_rounded, onMinus),
            Column(
              children: [
                // Keyed by value so every change replays the pop-in —
                // manual stepper taps get a subtle pop, and the
                // auto-progression bump gets pop + green flash with a
                // bouncing ↑ anchored to the value that actually moved.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (highlightValue)
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: _progressGreen,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -3, duration: 700.ms),
                    if (highlightValue) const SizedBox(width: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: highlightValue ? _progressGreen : textPrimary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    )
                        .animate(key: ValueKey('$label-$value'))
                        .scale(
                          begin: const Offset(1.22, 1.22),
                          end: const Offset(1, 1),
                          duration: 320.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(unit,
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
            _stepperBtn(Icons.add_rounded, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _unitToggle() {
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitOption('kg', _useKg),
          _unitOption('lb', !_useKg),
        ],
      ),
    );
  }

  Widget _unitOption(String label, bool selected) {
    final unselectedText = widget.isDark ? Colors.white60 : Colors.black54;
    return GestureDetector(
      // Opaque: without this the tappable area is only the text glyphs
      // themselves (padding defers hit-testing to the child), which made
      // the toggle feel dead.
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (label == 'kg' && _useKg) return;
        if (label == 'lb' && !_useKg) return;
        HapticFeedback.selectionClick();
        setState(() {
          // Convert weight when switching units so the value stays sensible.
          if (label == 'kg') {
            _weight = _weight / 2.20462;
            _useKg = true;
          } else {
            _weight = _weight * 2.20462;
            _useKg = false;
          }
        });
      },
      child: Container(
        // Vertical padding stays at 4: the Easy column is height-exact on
        // small screens (+4px here overflowed it by 1px). The tap target
        // is widened by HitTestBehavior.opaque above, not by padding.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : unselectedText,
          ),
        ),
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: _accent, size: 26),
      ),
    );
  }
}

/// Outlined chip — used for Adjust/Pyramid/Superset/L/R + footer chips.
class _OutlinedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;
  const _OutlinedChip(
      {required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Default to theme-aware muted text — `Colors.white70` was invisible
    // on the light-mode white background, hiding Adjust / Superset / L/R.
    final c = accent ??
        (isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6));
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced set tracking table — Set | Previous | TARGET | Wt | Reps | RIR | ✓
class _AdvancedSetTable extends StatelessWidget {
  final bool isDark;
  final List<int> targetWeights;
  final _DemoProgression progression;
  // Optional override — Frame 2 (set logged) shows the warmup row + set 1
  // checked off, with set 2 active. Frame 1 leaves only the warmup as active.
  final int activeRowIndex;
  final List<bool> completedRows;

  /// Callback fired when the user taps a row's checkbox. Frame 1's
  /// interactive demo wires this to the parent's `_toggleSetRow` so
  /// tapping the empty circles logs sets and auto-advances to Frame 2.
  /// `null` keeps the table read-only (Frame 2 reuses this widget for
  /// the after-state).
  final ValueChanged<int>? onToggleRow;

  /// Row whose target just auto-ramped after the previous set was
  /// checked — flashed green so progressive overload is visible.
  final int? flashRow;

  const _AdvancedSetTable({
    required this.isDark,
    required this.targetWeights,
    required this.progression,
    this.activeRowIndex = 0,
    this.completedRows = const [false, false, false, false],
    this.onToggleRow,
    this.flashRow,
  });

  static const _progressGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Warmup row + 3 working sets. Reps progression (low rep, more rep,
    // back to base, back to base) so the user sees a real wave/stair
    // pattern across the working sets.
    // Pull reps from the active progression so deltas look like real
    // overload (more weight, fewer reps).
    final reps = progression.targetReps;
    final rirByRow = [null, 4, 2, 2]; // warmup has no RIR

    // Pending cells — show '—' until that row is checked off.
    final wtCells = ['70', '—', '—', '—'];
    final repsCells = ['7', '—', '—', '—'];

    // When a row IS checked, populate Wt + Reps with the row's target
    // values from the active progression model. This is what makes the
    // "progression in action" visible — Linear shows even weights,
    // Step/Undulating show the curve.
    final completedWts = [
      '70',
      '${targetWeights[1]}',
      '${targetWeights[2]}',
      '${targetWeights[3]}',
    ];
    final completedReps = [
      '${reps[0]}',
      '${reps[1]}',
      '${reps[2]}',
      '${reps[3]}',
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _h('Set', 12, textSecondary),
                _h('Prev', 12, textSecondary),
                _h('TARGET', 26, textSecondary),
                _h('Wt', 14, textSecondary),
                _h('Reps', 14, textSecondary),
                _h('RIR', 10, textSecondary),
                const SizedBox(width: 26),
              ],
            ),
          ),
          // Warmup row (W)
          _row(
            rowIndex: 0,
            isWarmup: true,
            isActive: activeRowIndex == 0,
            isCompleted: completedRows[0],
            setLabel: 'W',
            previous: '—',
            target: '${targetWeights[0]} lb x ${reps[0]}',
            wt: completedRows[0] ? completedWts[0] : wtCells[0],
            reps: completedRows[0] ? completedReps[0] : repsCells[0],
            rir: null,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          // RIR scale row above working sets
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: const _RirScale(),
          ),
          // Working sets 1, 2, 3 — the warmup is the W row above, so
          // these are the user's 3 logged sets (not 2/3/4).
          for (int i = 1; i <= 3; i++)
            _row(
              rowIndex: i,
              isWarmup: false,
              isActive: activeRowIndex == i,
              isCompleted: completedRows[i],
              setLabel: '$i',
              previous: '—',
              target: '${targetWeights[i]} lb x ${reps[i]}',
              wt: completedRows[i] ? completedWts[i] : wtCells[i],
              reps: completedRows[i] ? completedReps[i] : repsCells[i],
              rir: rirByRow[i],
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _h(String label, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _row({
    required int rowIndex,
    required bool isWarmup,
    required bool isActive,
    required bool isCompleted,
    required String setLabel,
    required String previous,
    required String target,
    required String wt,
    required String reps,
    required int? rir,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final rirColor = _rirColor(rir);
    final flashing = flashRow == rowIndex && !isCompleted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: flashing
            ? _progressGreen.withValues(alpha: 0.12)
            : isActive
                ? AppColors.onboardingAccent.withValues(alpha: 0.12)
                : null,
        border: Border(
          top: BorderSide(
              color: textSecondary.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: isWarmup
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: textSecondary),
                    ),
                    child: Center(
                      child: Text(
                        'W',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  )
                : Text(
                    setLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              previous,
              style: TextStyle(fontSize: 15, color: textSecondary),
            ),
          ),
          Expanded(
            flex: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pops green while flashing — the target that Zealova
                // just auto-raised.
                Text(
                  target,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        flashing ? FontWeight.w800 : FontWeight.w600,
                    color: flashing ? _progressGreen : textPrimary,
                  ),
                ).animate(key: ValueKey('target-$rowIndex-$flashing')).scale(
                      begin: flashing
                          ? const Offset(1.15, 1.15)
                          : const Offset(1, 1),
                      end: const Offset(1, 1),
                      duration: 320.ms,
                      curve: Curves.easeOutBack,
                    ),
                if (rir != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rirColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'RIR $rir',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: rirColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: _cell(wt, isActive, textPrimary),
          ),
          Expanded(
            flex: 14,
            child: _cell(reps, isActive, textPrimary),
          ),
          // Inline arrow indicator — only renders on the first
          // uncompleted working set. The pulsing orange-bordered
          // checkbox carries most of the "tap here" signal; this
          // arrow just adds direction. Sized to fit the narrow flex
          // 10 column on every device.
          Expanded(
            flex: 10,
            child: flashing
                // Auto-progression flash — green ramp icon on the row
                // whose target Zealova just raised.
                ? Align(
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 18,
                      color: _progressGreen,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 2, end: -2, duration: 500.ms),
                  )
                : !isCompleted &&
                        !isWarmup &&
                        onToggleRow != null &&
                        _isFirstUncompletedRow(rowIndex)
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.orange,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveX(begin: 0, end: 4, duration: 700.ms),
                      )
                    : const SizedBox.shrink(),
          ),
          // Checkbox — tappable when `onToggleRow` is wired (Frame 1
          // interactive demo). Frame 2 reuses this widget read-only.
          // The first uncompleted row's checkbox pulses so the user
          // knows where to tap.
          GestureDetector(
            onTap: onToggleRow == null || isWarmup
                ? null
                : () => onToggleRow!(rowIndex),
            child: () {
              final box = isCompleted
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF22C55E), size: 22)
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: !isCompleted &&
                                  !isWarmup &&
                                  onToggleRow != null &&
                                  _isFirstUncompletedRow(rowIndex)
                              ? AppColors.orange
                              : textSecondary,
                          width: !isCompleted &&
                                  !isWarmup &&
                                  onToggleRow != null &&
                                  _isFirstUncompletedRow(rowIndex)
                              ? 2
                              : 1,
                        ),
                      ),
                    );
              // Pulse only the first uncompleted (active) circle.
              if (!isCompleted &&
                  !isWarmup &&
                  onToggleRow != null &&
                  _isFirstUncompletedRow(rowIndex)) {
                return box
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.18, 1.18),
                      duration: 700.ms,
                      curve: Curves.easeInOut,
                    );
              }
              return box;
            }(),
          ),
        ],
      ),
    );
  }

  Widget _cell(String value, bool isActive, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.orange.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
    );
  }

  Color _rirColor(int? rir) {
    if (rir == null) return Colors.transparent;
    if (rir >= 4) return const Color(0xFF22C55E);
    if (rir >= 2) return const Color(0xFFEAB308);
    if (rir >= 1) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  /// True if `rowIndex` is the first non-warmup row that hasn't been
  /// checked off yet. Drives where the "Tap to log" tooltip anchors.
  bool _isFirstUncompletedRow(int rowIndex) {
    for (int i = 1; i < completedRows.length; i++) {
      if (!completedRows[i]) return i == rowIndex;
    }
    return false;
  }
}


// ── Frame 2: set logged with progression delta
class _Frame2SetLogged extends StatelessWidget {
  final bool isDark;
  final _DemoProgression progression;
  const _Frame2SetLogged(
      {super.key, required this.isDark, required this.progression});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final w = progression.targetWeights;
    final r = progression.targetReps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Text(
              l10n.workoutShowcaseAllSetsLoggedProgression,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            );
          }).animate().fadeIn(),
          const SizedBox(height: 6),
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Text(
              "${progression.localizedLabel(l10n)} — ${progression.localizedDescription(l10n)}",
              style: TextStyle(fontSize: 13, color: textSecondary),
            );
          }).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 18),
          // ── Every set checked off. The progression deltas show how
          // weight + reps moved across the full session — what makes
          // the chosen progression model actually visible.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // No warmup row: the demo only logs the 3 working sets, so
                // showing a checked-off "W" the user never logged reads as
                // fake data.
                _progressionRow(
                  label: AppLocalizations.of(context)!.workoutShowcaseSet1,
                  weight: '${w[1]} lb',
                  reps: '${r[1]} reps',
                  delta: null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isCompleted: true,
                ),
                _deltaArrow(
                  weightDelta: w[2] - w[1] >= 0
                      ? '+${w[2] - w[1]} lb'
                      : '${w[2] - w[1]} lb',
                  repsDelta: _formatRepsDelta(r[2] - r[1]),
                  isUp: w[2] > w[1],
                ),
                _progressionRow(
                  label: AppLocalizations.of(context)!.workoutShowcaseSet2,
                  weight: '${w[2]} lb',
                  reps: '${r[2]} reps',
                  delta: null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isCompleted: true,
                ),
                _deltaArrow(
                  weightDelta: w[3] - w[2] >= 0
                      ? '+${w[3] - w[2]} lb'
                      : '${w[3] - w[2]} lb',
                  repsDelta: _formatRepsDelta(r[3] - r[2]),
                  isUp: w[3] >= w[2],
                ),
                _progressionRow(
                  label: AppLocalizations.of(context)!.workoutShowcaseSet3,
                  weight: '${w[3]} lb',
                  reps: '${r[3]} reps',
                  delta: null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isCompleted: true,
                  isCurrent: true,
                ),
              ],
            ),
          )
              .animate(delay: 220.ms)
              .fadeIn()
              .slideY(begin: 0.04, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF15803D), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.workoutShowcasePlanAutoAdjustsNext,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn(),
          const Spacer(),
          Builder(builder: (ctx) => _Annotation(
            text: AppLocalizations.of(ctx)!.workoutShowcaseEverySetYouLog,
          )).animate(delay: 700.ms).fadeIn(),
        ],
      ),
    );
  }

  /// Format an int rep delta as a human-readable label: "+2 reps",
  /// "−2 reps", or "0".
  String _formatRepsDelta(int delta) {
    if (delta == 0) return '0';
    if (delta > 0) return '+$delta reps';
    return '−${-delta} reps';
  }

  Widget _progressionRow({
    required String label,
    required String weight,
    required String reps,
    required String? delta,
    required Color textPrimary,
    required Color textSecondary,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isPending = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isPending ? textSecondary : textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.orange.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? AppColors.orange.withValues(alpha: 0.5)
                    : textSecondary.withValues(alpha: 0.15),
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weight,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? textSecondary
                        : (isCurrent ? AppColors.orange : textPrimary),
                  ),
                ),
                Text(
                  reps,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPending ? textSecondary : textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isCompleted
              ? const Color(0xFF22C55E)
              : textSecondary.withValues(alpha: 0.5),
          size: 22,
        ),
      ],
    );
  }

  Widget _deltaArrow({
    required String weightDelta,
    required String repsDelta,
    required bool isUp,
    bool isPending = false,
  }) {
    final color = isPending
        ? Colors.grey.withValues(alpha: 0.4)
        : (isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 56),
      child: Row(
        children: [
          Icon(
            isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            weightDelta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            repsDelta.contains('−')
                ? Icons.arrow_downward_rounded
                : Icons.remove_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            repsDelta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frame 3: workout complete
class _Frame3Complete extends StatefulWidget {
  final bool isDark;
  const _Frame3Complete({super.key, required this.isDark});

  @override
  State<_Frame3Complete> createState() => _Frame3CompleteState();
}

class _Frame3CompleteState extends State<_Frame3Complete> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    // One celebratory burst as the frame lands — feel-good spike right
    // before the shareable card.
    HapticFeedback.mediumImpact();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
          const SizedBox(height: 12),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 44),
          ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context)!.workoutShowcaseWorkoutComplete,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 18),
          Builder(builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return Row(
              children: [
                _StatTile(
                  icon: Icons.timer_rounded,
                  value: '44:12',
                  label: l10n.workoutShowcaseTime,
                  color: AppColors.onboardingAccent,
                  bg: cardBg,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '320',
                  label: l10n.workoutShowcaseCal,
                  color: const Color(0xFFE74C3C),
                  bg: cardBg,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatTile(
                  icon: Icons.scale_rounded,
                  value: '12,450',
                  label: l10n.workoutShowcaseVolume,
                  color: const Color(0xFF2ECC71),
                  bg: cardBg,
                  isDark: isDark,
                ),
              ],
            );
          }).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFE67E22), size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.workoutShowcase3Prs14Day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE67E22),
                  ),
                ),
              ],
            ),
          ).animate(delay: 600.ms).fadeIn(),
          const Spacer(),
          Builder(builder: (ctx) => _Annotation(
                  text: AppLocalizations.of(ctx)!.workoutShowcaseEveryWorkoutFlows))
              .animate(delay: 800.ms)
              .fadeIn(),
            ],
          ),
        ),
        // Confetti burst — explodes from the top center over the stats.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.onboardingAccent,
              Color(0xFF2ECC71),
              Colors.amber,
              Color(0xFF38BDF8),
              Colors.deepOrange,
            ],
            numberOfParticles: 35,
            maxBlastForce: 22,
            minBlastForce: 6,
            emissionFrequency: 0.05,
            gravity: 0.22,
          ),
        ),
      ],
    );
  }
}

// ── Frame 4: shareable
/// 15 distinct shareable formats — gallery picker (all visible at once)
/// + tappable big preview. Per project memory:
/// `feedback_share_gallery_viral_templates.md` — gallery, not carousel,
/// 15+ viral formats not polished variations of one tile.
enum _ShareFormat {
  card,
  receipt,
  newspaper,
  flightTicket,
  instaStory,
  tradingCard,
  polaroid,
  wrapped,
  trophy,
  prCard,
  oneRm,
  fullWorkout,
  vinyl,
  discord,
  quote,
  passport,
}

extension _ShareFormatMeta on _ShareFormat {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case _ShareFormat.card:
        return l10n.workoutShowcaseFormatCard;
      case _ShareFormat.receipt:
        return l10n.workoutShowcaseFormatReceipt;
      case _ShareFormat.newspaper:
        return l10n.workoutShowcaseFormatNewspaper;
      case _ShareFormat.flightTicket:
        return l10n.workoutShowcaseFormatBoarding;
      case _ShareFormat.instaStory:
        return l10n.workoutShowcaseFormatIgStory;
      case _ShareFormat.tradingCard:
        return l10n.workoutShowcaseFormatTrading;
      case _ShareFormat.polaroid:
        return l10n.workoutShowcaseFormatPolaroid;
      case _ShareFormat.wrapped:
        return l10n.workoutShowcaseFormatWrapped;
      case _ShareFormat.trophy:
        return l10n.workoutShowcaseFormatTrophy;
      case _ShareFormat.prCard:
        return l10n.workoutShowcaseFormatPrCard;
      case _ShareFormat.oneRm:
        return l10n.workoutShowcaseFormat1Rm;
      case _ShareFormat.fullWorkout:
        return l10n.workoutShowcaseFormatFull;
      case _ShareFormat.vinyl:
        return l10n.workoutShowcaseFormatVinyl;
      case _ShareFormat.discord:
        return l10n.workoutShowcaseFormatDiscord;
      case _ShareFormat.quote:
        return l10n.workoutShowcaseFormatQuote;
      case _ShareFormat.passport:
        return l10n.workoutShowcaseFormatPassport;
    }
  }
}

class _Frame4Shareable extends StatefulWidget {
  final bool isDark;
  final String? userFirstName;
  const _Frame4Shareable({
    super.key,
    required this.isDark,
    this.userFirstName,
  });

  @override
  State<_Frame4Shareable> createState() => _Frame4ShareableState();
}

class _Frame4ShareableState extends State<_Frame4Shareable> {
  // Default to Wrapped — the demo runs pre-signup (no name available),
  // and without personalization the Spotify-Wrapped-style gradient is
  // the strongest opener: instantly recognizable meme format, vibrant
  // color that pops against the black screen, and "TOP 5% · 3 PRs" is
  // an aspirational flex that needs no name. The generic orange stat
  // Card it replaces was the weakest of the fifteen.
  _ShareFormat _selected = _ShareFormat.wrapped;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.workoutShowcaseShareYourWorkout,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.4,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.workoutShowcaseViralFormatsTap,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 14),
          // ── Big preview (renders the currently selected format)
          Center(
            child: SizedBox(
              key: ValueKey(_selected),
              width: 230,
              height: 280,
              child: _ShareRenderer(
                format: _selected,
                mini: false,
                userFirstName: widget.userFirstName,
              ),
            )
                .animate(key: ValueKey(_selected))
                .fadeIn(duration: 250.ms)
                .scale(begin: const Offset(0.95, 0.95)),
          ),
          const SizedBox(height: 14),
          // ── Gallery: scrollable 5-col grid. Labels were getting
          // clipped under the bottom CTA — letting it scroll lets the
          // user see every format's label cleanly.
          Expanded(
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.7,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              children: _ShareFormat.values.map((f) {
                final selected = f == _selected;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = f);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.orange
                            : (isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Render the format at FULL size and scale-fit
                        // it into the tiny cell. Avoids re-tuning every
                        // sub-layout for the gallery thumb size — gallery
                        // is just a shrunken big-preview.
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: 230,
                                height: 280,
                                child: _ShareRenderer(
                                  format: f,
                                  mini: false,
                                  userFirstName: widget.userFirstName,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            f.localizedLabel(AppLocalizations.of(context)!),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? AppColors.orange
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single dispatcher — every format renders here in either mini (gallery
/// tile) or full-size mode. Same workout data on all formats so the user
/// can compare side-by-side.
class _ShareRenderer extends StatelessWidget {
  final _ShareFormat format;
  final bool mini;
  final String? userFirstName;
  const _ShareRenderer({
    required this.format,
    required this.mini,
    this.userFirstName,
  });

  // Shared mock workout data — passed to every renderer.
  static const _data = (
    title: 'UPPER BODY PUSH',
    duration: '44 min',
    volume: '12,450 lbs',
    prs: 3,
    day: 14,
    benchPr: '225 lb × 5',
    overheadPr: '155 lb × 8',
    inclinePr: '185 lb × 6',
  );

  @override
  Widget build(BuildContext context) {
    switch (format) {
      case _ShareFormat.card:
        return _renderCard(mini);
      case _ShareFormat.receipt:
        return _renderReceipt(mini);
      case _ShareFormat.newspaper:
        return _renderNewspaper(mini);
      case _ShareFormat.flightTicket:
        return _renderBoarding(mini);
      case _ShareFormat.instaStory:
        return _renderInstaStory(mini);
      case _ShareFormat.tradingCard:
        return _renderTradingCard(mini);
      case _ShareFormat.polaroid:
        return _renderPolaroid(mini);
      case _ShareFormat.wrapped:
        return _renderWrapped(mini);
      case _ShareFormat.trophy:
        return _renderTrophy(mini);
      case _ShareFormat.prCard:
        return _renderPrCard(mini);
      case _ShareFormat.oneRm:
        return _renderOneRm(mini);
      case _ShareFormat.fullWorkout:
        return _renderFullWorkout(mini);
      case _ShareFormat.vinyl:
        return _renderVinyl(mini);
      case _ShareFormat.discord:
        return _renderDiscord(mini);
      case _ShareFormat.quote:
        return _renderQuote(mini);
      case _ShareFormat.passport:
        return _renderPassport(mini);
    }
  }

  // ─── Format renderers ───────────────────────────────────────────
  // Each accepts `mini` and scales font sizes / paddings so the gallery
  // tile reads the same as the big preview. All dimensions are %-based
  // off `mini ? 0.45 : 1.0` so layouts compose cleanly.

  double _s(double base) => mini ? base * 0.42 : base;

  Widget _renderCard(bool m) => Container(
        padding: EdgeInsets.all(_s(20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orange, Color(0xFFFF6B00)],
          ),
          borderRadius: BorderRadius.circular(_s(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_data.title,
                style: TextStyle(
                  fontSize: _s(10),
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: _s(2),
                )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_data.duration,
                    style: TextStyle(
                      fontSize: _s(36),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    )),
                SizedBox(height: _s(4)),
                Text('${_data.volume} · ${_data.prs} PRs',
                    style: TextStyle(
                      fontSize: _s(14),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ],
            ),
            Text('YOU · DAY ${_data.day}',
                style: TextStyle(
                  fontSize: _s(11),
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: _s(1.5),
                )),
          ],
        ),
      );

  Widget _renderReceipt(bool m) => Container(
        padding: EdgeInsets.all(_s(14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F1),
          borderRadius: BorderRadius.circular(_s(8)),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: _s(10),
            color: Colors.black87,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                  child: Text('** ZEALOVA **',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: _s(12),
                          fontFamily: 'Courier'))),
              Text('${'-' * 24}', style: TextStyle(fontSize: _s(8))),
              Text('SESSION: ${_data.title}'),
              Text('DURATION: ${_data.duration}'),
              Text('VOLUME:   ${_data.volume}'),
              Text('PRS:      ${_data.prs}'),
              Text('${'-' * 24}', style: TextStyle(fontSize: _s(8))),
              Text('TOTAL'),
              Text('GAINS UNLOCKED',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: _s(13),
                      fontFamily: 'Courier')),
              Text('${'=' * 24}', style: TextStyle(fontSize: _s(8))),
              Center(
                  child: Text('DAY ${_data.day} · KEEP GOING',
                      style: TextStyle(fontSize: _s(8)))),
            ],
          ),
        ),
      );

  Widget _renderNewspaper(bool m) => Container(
        padding: EdgeInsets.all(_s(14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCF6),
          borderRadius: BorderRadius.circular(_s(6)),
          border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
                child: Text('THE GAINS GAZETTE',
                    style: TextStyle(
                        fontFamily: 'Times',
                        fontSize: _s(11),
                        fontWeight: FontWeight.w800,
                        letterSpacing: _s(1.5),
                        color: Colors.black))),
            Container(
                height: _s(2), color: Colors.black, margin: EdgeInsets.symmetric(vertical: _s(6))),
            // Pre-signup there's no name yet — "YOU LIFT" keeps the
            // headline second-person personal instead of a generic
            // "ATHLETE LIFTS".
            Text(
                userFirstName != null
                    ? '$userFirstName LIFTS\n${_data.volume}'
                    : 'YOU LIFT\n${_data.volume}',
                style: TextStyle(
                    fontFamily: 'Times',
                    fontSize: _s(20),
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Colors.black)),
            SizedBox(height: _s(6)),
            Text(
                userFirstName != null
                    ? '"Just another Tuesday," says ${userFirstName!.toLowerCase().replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase())} after destroying a ${_data.duration} session with ${_data.prs} new personal records.'
                    : '"Just another Tuesday," you say, after destroying a ${_data.duration} session with ${_data.prs} new personal records.',
                style: TextStyle(
                    fontFamily: 'Times',
                    fontSize: _s(9),
                    color: Colors.black87,
                    height: 1.3)),
            SizedBox(height: _s(6)),
            Text('VOL. ${_data.day} · ZEALOVA PRESS',
                style: TextStyle(
                    fontFamily: 'Times',
                    fontSize: _s(8),
                    color: Colors.black54)),
          ],
        ),
      );

  Widget _renderBoarding(bool m) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_s(8)),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(_s(10)),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(_s(8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BOARDING PASS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: _s(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: _s(1.5))),
                  Text('ZL ${_data.day.toString().padLeft(3, '0')}',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: _s(9),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(_s(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GYM',
                                style: TextStyle(
                                    fontSize: _s(9),
                                    color: Colors.black54)),
                            Text('SOFA',
                                style: TextStyle(
                                    fontSize: _s(20),
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Icon(Icons.flight_takeoff_rounded,
                            size: _s(20), color: const Color(0xFF0F172A)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('GAINS',
                                style: TextStyle(
                                    fontSize: _s(9),
                                    color: Colors.black54)),
                            Text('PEAK',
                                style: TextStyle(
                                    fontSize: _s(20),
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _bp('FLIGHT', 'ZL ${_data.day}', _s),
                        _bp('GATE', '${_data.prs} PR', _s),
                        _bp('SEAT', '1A', _s),
                      ],
                    ),
                    Container(
                      height: _s(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.black, Color(0xFF333)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bp(String k, String v, double Function(double) s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: s(8), color: Colors.black45)),
          Text(v,
              style: TextStyle(
                  fontSize: s(11), fontWeight: FontWeight.w800)),
        ],
      );

  Widget _renderInstaStory(bool m) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEC4899),
              Color(0xFFF97316),
              Color(0xFFEAB308),
            ],
          ),
          borderRadius: BorderRadius.circular(_s(12)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💪',
                      style: TextStyle(fontSize: _s(40))),
                  SizedBox(height: _s(8)),
                  Text(_data.volume.toUpperCase(),
                      style: TextStyle(
                        fontSize: _s(28),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      )),
                  SizedBox(height: _s(4)),
                  Text('IN ${_data.duration.toUpperCase()}',
                      style: TextStyle(
                          fontSize: _s(11),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: _s(2))),
                ],
              ),
            ),
            Positioned(
              top: _s(12),
              left: _s(12),
              right: _s(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _s(8), vertical: _s(3)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(_s(20)),
                    ),
                    child: Text('@you',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: _s(9),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: _s(12),
              left: _s(12),
              child: Text('zealova',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: _s(10),
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      );

  Widget _renderTradingCard(bool m) => Container(
        padding: EdgeInsets.all(_s(8)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBBF24), Color(0xFFEAB308), Color(0xFFCA8A04)],
          ),
          borderRadius: BorderRadius.circular(_s(10)),
          border: Border.all(color: const Color(0xFF422006), width: _s(2)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(_s(6)),
          ),
          padding: EdgeInsets.all(_s(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PUSH',
                      style: TextStyle(
                          color: const Color(0xFFFBBF24),
                          fontSize: _s(9),
                          fontWeight: FontWeight.w800)),
                  Text('★ RARE',
                      style: TextStyle(
                          color: const Color(0xFFFBBF24),
                          fontSize: _s(8),
                          fontWeight: FontWeight.w800)),
                ],
              ),
              SizedBox(height: _s(6)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_s(4)),
                  child: Image.asset(
                    'assets/images/exercises/barbell_squat.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: _s(6)),
              Text('YOU',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: _s(15),
                      fontWeight: FontWeight.w900)),
              Container(
                height: _s(1),
                color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                margin: EdgeInsets.symmetric(vertical: _s(3)),
              ),
              _stat(' VOL', _data.volume, m),
              _stat(' PRS', '${_data.prs}', m),
              _stat(' DAY', '${_data.day}', m),
            ],
          ),
        ),
      );

  Widget _stat(String k, String v, bool m) => Padding(
        padding: EdgeInsets.symmetric(vertical: _s(1)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    color: const Color(0xFFFBBF24),
                    fontSize: _s(8),
                    fontWeight: FontWeight.w700)),
            Text(v,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _s(9),
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _renderPolaroid(bool m) => Container(
        padding: EdgeInsets.fromLTRB(_s(10), _s(10), _s(10), _s(28)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_s(4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: _s(8),
              offset: Offset(0, _s(4)),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_s(2)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                    ),
                  ),
                  child: Center(
                    child: Text('💪',
                        style: TextStyle(fontSize: _s(56))),
                  ),
                ),
              ),
            ),
            SizedBox(height: _s(8)),
            Text('${_data.duration} · ${_data.volume}',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: _s(11),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                )),
            SizedBox(height: _s(2)),
            Text('day ${_data.day} ✨',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: _s(9),
                    color: Colors.black54)),
          ],
        ),
      );

  Widget _renderWrapped(bool m) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(_s(14)),
        ),
        padding: EdgeInsets.all(_s(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ZEALOVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _s(11),
                  fontWeight: FontWeight.w800,
                  letterSpacing: _s(2),
                )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${_data.day}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _s(13),
                      fontWeight: FontWeight.w700,
                    )),
                Text('${_data.volume.split(' ').first} lbs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _s(36),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    )),
                Text('moved this session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _s(13),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            Text('TOP 5% · ${_data.prs} PRS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _s(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: _s(2),
                )),
          ],
        ),
      );

  Widget _renderTrophy(bool m) => Container(
        padding: EdgeInsets.all(_s(14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(_s(8)),
          border: Border.all(
              color: const Color(0xFFCA8A04), width: _s(3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('🏆',
                style: TextStyle(fontSize: _s(40))),
            Text('CERTIFICATE OF',
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(9),
                  letterSpacing: _s(2),
                  color: const Color(0xFFCA8A04),
                )),
            Text('ACHIEVEMENT',
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(18),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF422006),
                )),
            Text('Awarded for',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: _s(9),
                    color: Colors.black54)),
            Text(_data.volume,
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(18),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF422006),
                )),
            Text('moved on day ${_data.day}',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: _s(9),
                    color: Colors.black54)),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: _s(10), vertical: _s(3)),
              decoration: BoxDecoration(
                color: const Color(0xFFCA8A04),
                borderRadius: BorderRadius.circular(_s(20)),
              ),
              child: Text('${_data.prs} PRS · ELITE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: _s(8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: _s(1.5))),
            ),
          ],
        ),
      );

  Widget _renderPrCard(bool m) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(_s(12)),
        ),
        padding: EdgeInsets.all(_s(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: _s(8), vertical: _s(3)),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(_s(4)),
              ),
              child: Text('NEW PR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _s(9),
                    fontWeight: FontWeight.w900,
                    letterSpacing: _s(2),
                  )),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BENCH PRESS',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: _s(11),
                      fontWeight: FontWeight.w700,
                      letterSpacing: _s(1.5),
                    )),
                Text(_data.benchPr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _s(28),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    )),
                SizedBox(height: _s(8)),
                Text('OVERHEAD ${_data.overheadPr}',
                    style: TextStyle(
                      color: const Color(0xFF22C55E),
                      fontSize: _s(11),
                      fontWeight: FontWeight.w800,
                    )),
                Text('INCLINE ${_data.inclinePr}',
                    style: TextStyle(
                      color: const Color(0xFF22C55E),
                      fontSize: _s(11),
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            Text('${_data.prs} RECORDS BROKEN · DAY ${_data.day}',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: _s(9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: _s(1))),
          ],
        ),
      );

  Widget _renderOneRm(bool m) => Container(
        padding: EdgeInsets.all(_s(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_s(10)),
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1RM ESTIMATE',
                style: TextStyle(
                  fontSize: _s(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: _s(2),
                  color: AppColors.orange,
                )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BENCH PRESS',
                    style: TextStyle(
                        fontSize: _s(11), color: Colors.black54)),
                Text('252 lb',
                    style: TextStyle(
                      fontSize: _s(36),
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1,
                    )),
                SizedBox(height: _s(4)),
                Text('Epley · 225 × 5 reps',
                    style: TextStyle(
                        fontSize: _s(10), color: Colors.black54)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _oneRmRow('SQUAT', '315 lb', m),
                _oneRmRow('DEADLIFT', '385 lb', m),
                _oneRmRow('OHP', '155 lb', m),
              ],
            ),
          ],
        ),
      );

  Widget _oneRmRow(String k, String v, bool m) => Padding(
        padding: EdgeInsets.symmetric(vertical: _s(2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                  fontSize: _s(9),
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                )),
            Text(v,
                style: TextStyle(
                  fontSize: _s(11),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                )),
          ],
        ),
      );

  /// Full workout receipt — itemized exercise list with sets / weight /
  /// reps per row, total volume + duration footer, NEW PR pills on top
  /// 3 lifts. The "data-rich" share — proves the workout actually
  /// happened set-by-set instead of just reading aggregate stats.
  Widget _renderFullWorkout(bool m) {
    const exercises = [
      ('BENCH PRESS', '225 × 5', true),
      ('OVERHEAD PRESS', '155 × 8', true),
      ('INCLINE PRESS', '185 × 6', true),
      ('DUMBBELL FLY', '50 × 12', false),
      ('TRICEP PUSHDOWN', '80 × 12', false),
    ];
    return Container(
      padding: EdgeInsets.all(_s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F1),
        borderRadius: BorderRadius.circular(_s(8)),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Times',
          color: Colors.black87,
          fontSize: _s(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: Text(
                'ZEALOVA',
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(11),
                  fontWeight: FontWeight.w800,
                  letterSpacing: _s(2),
                  color: Colors.black,
                ),
              ),
            ),
            Center(
              child: Text(
                _data.title,
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(15),
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
                height: _s(1),
                color: Colors.black,
                margin: EdgeInsets.symmetric(vertical: _s(4))),
            ...exercises.asMap().entries.map((e) {
              final idx = e.key + 1;
              final (name, target, isPr) = e.value;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: _s(2)),
                child: Row(
                  children: [
                    SizedBox(
                      width: _s(14),
                      child: Text('$idx.',
                          style: TextStyle(
                              fontFamily: 'Times',
                              fontSize: _s(10),
                              color: Colors.black54)),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontSize: _s(11),
                            fontWeight: FontWeight.w800,
                            color: Colors.black),
                      ),
                    ),
                    Text(target,
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontSize: _s(11),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    if (isPr) ...[
                      SizedBox(width: _s(4)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: _s(4), vertical: _s(1)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(_s(2)),
                        ),
                        child: Text('PR',
                            style: TextStyle(
                                fontFamily: 'Times',
                                fontSize: _s(7),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: _s(0.5))),
                      ),
                    ],
                  ],
                ),
              );
            }),
            Container(
                height: _s(1),
                color: Colors.black,
                margin: EdgeInsets.symmetric(vertical: _s(4))),
            Center(
              child: Text(
                'TOTAL  ${_data.duration} · ${_data.volume} · ${_data.prs} PRS',
                style: TextStyle(
                    fontFamily: 'Times',
                    fontSize: _s(10),
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ),
            ),
            Center(
              child: Text(
                'DAY ${_data.day} · @${(userFirstName ?? "you").toLowerCase()}',
                style: TextStyle(
                  fontFamily: 'Times',
                  fontSize: _s(8),
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderVinyl(bool m) => Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(_s(10)),
        ),
        padding: EdgeInsets.all(_s(14)),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                ...List.generate(
                    5,
                    (i) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: _s(0.6),
                            ),
                          ),
                          margin: EdgeInsets.all(_s(8.0 + i * 6)),
                        )),
                Container(
                  width: _s(80),
                  height: _s(80),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.orange, Color(0xFFFF6B00)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SIDE A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _s(8),
                              fontWeight: FontWeight.w800,
                              letterSpacing: _s(1.5),
                            )),
                        Text(_data.duration,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _s(15),
                              fontWeight: FontWeight.w900,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _renderDiscord(bool m) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF36393F),
          borderRadius: BorderRadius.circular(_s(6)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: _s(4),
                color: AppColors.orange,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_s(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Real Zealova app icon as Discord server avatar.
                          Container(
                            width: _s(16),
                            height: _s(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: _s(5)),
                          Text('Zealova',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _s(10),
                                fontWeight: FontWeight.w800,
                              )),
                        ],
                      ),
                      Text('Workout logged',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _s(13),
                            fontWeight: FontWeight.w800,
                          )),
                      Wrap(
                        spacing: _s(8),
                        runSpacing: _s(4),
                        children: [
                          _disField('DURATION', _data.duration, m),
                          _disField('VOLUME', _data.volume, m),
                          _disField('PRS', '${_data.prs}', m),
                          _disField('DAY', '${_data.day}', m),
                        ],
                      ),
                      Text('Powered by Zealova',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: _s(8),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _disField(String k, String v, bool m) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: TextStyle(
                color: Colors.white60,
                fontSize: _s(8),
                fontWeight: FontWeight.w700,
              )),
          Text(v,
              style: TextStyle(
                color: Colors.white,
                fontSize: _s(11),
                fontWeight: FontWeight.w800,
              )),
        ],
      );

  Widget _renderQuote(bool m) => Container(
        padding: EdgeInsets.all(_s(14)),
        decoration: BoxDecoration(
          color: const Color(0xFF15202B),
          borderRadius: BorderRadius.circular(_s(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: _s(28),
                  height: _s(28),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: _s(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _s(11),
                          fontWeight: FontWeight.w800,
                        )),
                    Text('@you · day ${_data.day}',
                        style: TextStyle(
                            color: Colors.white60, fontSize: _s(9))),
                  ],
                ),
              ],
            ),
            Text(
                'Just moved ${_data.volume} in ${_data.duration}.\n${_data.prs} new PRs.\n\nBuilt different.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _s(13),
                  height: 1.4,
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.favorite_border,
                    size: _s(13), color: Colors.white60),
                Icon(Icons.repeat, size: _s(13), color: Colors.white60),
                Icon(Icons.share_outlined,
                    size: _s(13), color: Colors.white60),
              ],
            ),
          ],
        ),
      );

  Widget _renderPassport(bool m) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(_s(8)),
        ),
        padding: EdgeInsets.all(_s(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌍',
                    style: TextStyle(fontSize: _s(20))),
                Text('PASSPORT',
                    style: TextStyle(
                        color: const Color(0xFFFBBF24),
                        fontSize: _s(11),
                        fontWeight: FontWeight.w900,
                        letterSpacing: _s(2))),
              ],
            ),
            Container(
              padding: EdgeInsets.all(_s(10)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_s(4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAMP #${_data.day}',
                      style: TextStyle(
                          fontSize: _s(8), color: Colors.black54)),
                  Text('ZEALOVA',
                      style: TextStyle(
                        fontSize: _s(15),
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E3A8A),
                      )),
                  Text(_data.title,
                      style: TextStyle(
                          fontSize: _s(9),
                          color: Colors.black87,
                          fontWeight: FontWeight.w700)),
                  Text('${_data.duration} · ${_data.volume}',
                      style: TextStyle(
                          fontSize: _s(9), color: Colors.black54)),
                  SizedBox(height: _s(4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _s(6), vertical: _s(2)),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFEF4444), width: _s(1.5)),
                      borderRadius: BorderRadius.circular(_s(2)),
                    ),
                    child: Text('${_data.prs} PRS · ENTERED',
                        style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: _s(8),
                            fontWeight: FontWeight.w800,
                            letterSpacing: _s(1))),
                  ),
                ],
              ),
            ),
            Text('GAINS · ${_data.day} · 1A',
                style: TextStyle(
                    color: const Color(0xFFFBBF24),
                    fontSize: _s(8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: _s(2))),
          ],
        ),
      );
}

// ── Helpers

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SetTable extends StatelessWidget {
  final bool isDark;
  final List<_Row> rows;
  const _SetTable({required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _hCell('SET', 0.13, textSecondary),
                _hCell('TARGET', 0.32, textSecondary),
                _hCell('WT', 0.20, textSecondary),
                _hCell('REPS', 0.20, textSecondary),
                _hCell('✓', 0.15, textSecondary),
              ],
            ),
          ),
          ...rows.map((r) => _buildRow(r, textPrimary, textSecondary, isDark)),
        ],
      ),
    );
  }

  Widget _hCell(String t, double f, Color c) {
    return Expanded(
      flex: (f * 100).round(),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: c,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRow(
      _Row r, Color textPrimary, Color textSecondary, bool isDark) {
    final accent = r.active ? AppColors.onboardingAccent : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: r.active
            ? AppColors.onboardingAccent.withValues(alpha: 0.08)
            : null,
        border: Border(
          top: BorderSide(
              color: textSecondary.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 13,
            child: Text(
              r.set,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent ?? textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 32,
            child: Text(
              r.target,
              style: TextStyle(
                fontSize: 13,
                color: r.done ? textSecondary : textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              r.wt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent ?? textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              r.reps,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent ?? textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: r.done
                ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2ECC71), size: 18)
                : Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final String set;
  final String target;
  final String wt;
  final String reps;
  final bool done;
  final bool active;
  const _Row({
    required this.set,
    required this.target,
    this.wt = '',
    this.reps = '',
    this.done = false,
    this.active = false,
  });
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;
  final bool isDark;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTab extends StatelessWidget {
  final String label;
  final bool active;
  const _ShareTab({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.onboardingAccent
            : AppColors.onboardingAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppColors.onboardingAccent,
        ),
      ),
    );
  }
}

class _Annotation extends StatelessWidget {
  final String text;
  const _Annotation({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.onboardingAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onboardingAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.onboardingAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
