/// Tier-keyed Active-Workout tour step lists + per-tier seen-flag persistence.
///
/// Task #13 of the Easy/Simple/Advanced tier plan (image-1-so-i-generic-honey.md):
/// the coach-mark tour adapts to whichever workout-UI tier the user is currently
/// on. Three separate step lists (Easy = 3, Simple = 5, Advanced = 7), three
/// separate SharedPreferences flags (`tour_seen_easy`, `tour_seen_simple`,
/// `tour_seen_advanced`), so a user who graduates Easy → Simple → Advanced
/// gets a fresh tour at each step without ever re-seeing a tier they already
/// completed.
///
/// Step copy in this file is taken verbatim from the plan's "App Tour —
/// tier-aware" section. Do not paraphrase — the wording was user-approved.
///
/// Integration hook: `workout_flow_mixin.triggerWorkoutTour()` reads
/// `workoutUiModeProvider` and calls `WorkoutTourService.maybeShowForTier()`.
/// Tier switches mid-tour abort the current tour and re-fire for the new tier
/// (if that tier's seen flag is also false).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/workout_ui_mode_provider.dart';
import '../../widgets/app_tour/app_tour_controller.dart';

/// Canonical SharedPreferences key prefix for the per-tier seen flag.
/// Full keys: `tour_seen_easy`, `tour_seen_simple`, `tour_seen_advanced`.
const String _tourSeenPrefix = 'tour_seen_';

/// Stable tour-id per tier — used as the [AppTourController] `tourId` so the
/// controller's own dismissal machinery has something unique to hang off of.
/// Note: canonical persistence of "seen" state is owned by this file via the
/// `tour_seen_<tier>` keys above. The controller's built-in
/// `has_seen_<tourId>` keys are also written by `dismiss()`, and we mirror
/// them into our canonical keys on that event.
String tourIdForTier(WorkoutUiMode tier) => switch (tier) {
      WorkoutUiMode.easy => 'workout_tour_easy',
      // ignore: deprecated_member_use_from_same_package
      WorkoutUiMode.simple => 'workout_tour_easy',
      WorkoutUiMode.advanced => 'workout_tour_advanced',
    };

String _seenKeyForTier(WorkoutUiMode tier) =>
    '$_tourSeenPrefix${tier.asString}';

/// Reverse lookup — which tier (if any) does this running tourId belong to?
WorkoutUiMode? _tierForTourId(String? tourId) => switch (tourId) {
      'workout_tour_easy' => WorkoutUiMode.easy,
      'workout_tour_simple' => WorkoutUiMode.easy, // legacy id → easy.
      'workout_tour_advanced' => WorkoutUiMode.advanced,
      _ => null,
    };

/// Easy tour — 3 steps. First-timer vocabulary; avoids any advanced concepts.
/// The Easy active-workout screen attaches Easy-OWN anchors —
/// `easyExerciseHeaderKey` on the exercise header, `easyStepperKey` on the
/// weight/reps steppers, and `easyLogSetButtonKey` on the LOG SET button — so
/// each step spotlights a DISTINCT Easy widget (steps 2 & 3 no longer share a
/// target) with an animated highlight ring. These keys are also separate from
/// the Advanced tree's `exerciseCard`/`setLogging` keys, so the two screens
/// never collide during the Easy↔Advanced AnimatedSwitcher transition.
List<AppTourStep> easyTourSteps() => [
      AppTourStep(
        id: 'workout_easy_step_header',
        targetKey: AppTourKeys.easyExerciseHeaderKey,
        title: "Today's exercise",
        description:
            "This is today's exercise. Tap ▶ to watch the demo if you need form help.",
        position: TooltipPosition.below,
        cornerRadius: 18,
        highlightColors: _easyHighlight,
      ),
      AppTourStep(
        id: 'workout_easy_step_stepper',
        targetKey: AppTourKeys.easyStepperKey,
        title: 'Log your effort',
        description:
            'Dial in weight & reps — or distance/time for cardio — with − and +. Tap a number to type it.',
        position: TooltipPosition.above,
        cornerRadius: 18,
        highlightColors: _easyHighlight,
      ),
      AppTourStep(
        id: 'workout_easy_step_log',
        targetKey: AppTourKeys.easyLogSetButtonKey,
        title: 'Finish the set',
        description:
            "Tap LOG SET when you finish. We'll handle the rest — literally.",
        position: TooltipPosition.above,
        cornerRadius: 18,
        highlightColors: _easyHighlight,
      ),
    ];

/// Animated spotlight-ring gradient for the Easy tour (brand green → cyan).
const List<Color> _easyHighlight = [
  Color(0xFF4ADE80),
  Color(0xFF22D3EE),
  Color(0xFF3B82F6),
  Color(0xFF4ADE80),
];

/// Simple tour — 5 steps. Introduces rail editing, Prev auto-fill, rest
/// adjustment, the coach chat bar, and the tier toggle graduation path.
/// TODO(tier-ui): replace reused Advanced keys with Simple-screen-specific
/// keys (`simpleRailKey`, `simplePrevLineKey`, `simpleRestBarKey`,
/// `simpleChatBarKey`, `tierToggleKey`) once the Simple screen ships.
List<AppTourStep> simpleTourSteps() => [
      AppTourStep(
        id: 'workout_simple_step_rail',
        targetKey: AppTourKeys.setLoggingKey,
        title: 'Your sets',
        description: 'Your sets live here. Tap any pill to edit that set.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_simple_step_prev',
        targetKey: AppTourKeys.exerciseCardKey,
        title: 'Last session, pre-loaded',
        description:
            "Your last session's values are already loaded — tap ✓ to log if nothing changed.",
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_simple_step_rest',
        targetKey: AppTourKeys.restTimerKey,
        title: 'Rest timer',
        description:
            'Rest starts automatically. Use −15 / +15 if you need more or less.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_simple_step_chat',
        targetKey: AppTourKeys.workoutAiKey,
        title: 'Ask your coach',
        description:
            "Stuck? Ask your coach — 'Is this too heavy?', 'Swap this exercise', anything.",
        position: TooltipPosition.above,
        cornerRadius: 999,
        highlightColors: const [
          Color(0xFF9B59B6),
          Color(0xFF00BCD4),
          Color(0xFF3B82F6),
          Color(0xFF9B59B6),
        ],
      ),
      AppTourStep(
        id: 'workout_simple_step_tier_toggle',
        targetKey: AppTourKeys.swapExerciseKey,
        title: 'Ready for more?',
        description:
            'Ready for more detail? Switch to Advanced anytime from here.',
        position: TooltipPosition.above,
      ),
    ];

/// Advanced tour — 6 steps. Exercise → sets → RIR → swap → AI coach → tier
/// toggle. (The old "Rest Timer" step was pulled out into a contextual
/// coach-mark — see `restCoachmarkSteps()` — because its target only exists on
/// screen during an active rest, never at upfront-tour time.)
/// TODO(tier-ui): once the tier toggle is added to `workout_top_bar_v2.dart`,
/// wrap it with `key: AppTourKeys.tierToggleKey` and swap the final step's
/// target from `swapExerciseKey` to `tierToggleKey`.
List<AppTourStep> advancedTourSteps() => [
      AppTourStep(
        id: 'workout_step_exercise',
        targetKey: AppTourKeys.exerciseCardKey,
        title: 'Welcome to Advanced',
        description:
            'Advanced mode gives you full per-set logging. This is your current exercise. Follow the video, or tap Info for the full how-to.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_sets',
        targetKey: AppTourKeys.setLoggingKey,
        title: 'Log Your Sets',
        description:
            'Enter weight and reps, then check the box to complete each set. Your history saves automatically.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_rir',
        targetKey: AppTourKeys.rirBarKey,
        title: 'Rate Your Effort (RIR)',
        description:
            'RIR = Reps In Reserve. How many more reps could you do? 0 means failure, 5+ means easy. This helps the AI adjust your future weights.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_swap',
        targetKey: AppTourKeys.swapExerciseKey,
        title: "Can't Do This?",
        description:
            'Swap any exercise for a suitable alternative, create a superset, or switch sides with L/R.',
        position: TooltipPosition.above,
      ),
      // NOTE: the "Rest Timer" step is intentionally NOT here. The rest-timer
      // widget (inline rest row) only mounts during an active between-set rest,
      // so it's never on screen when this upfront tour runs — the spotlight had
      // no target and showed a dimmed screen with no highlight. It's now a
      // contextual one-time coach-mark fired the first time a real rest starts
      // (see `restCoachmarkSteps()` + `WorkoutTourService.maybeShowRestCoachmark`).
      AppTourStep(
        id: 'workout_step_ai',
        targetKey: AppTourKeys.workoutAiKey,
        title: 'Your AI Coach',
        description:
            'Ask your coach anything mid-workout — form check, exercise alternatives, weight suggestions, or just how many sets you have left.',
        position: TooltipPosition.above,
        cornerRadius: 999,
        highlightColors: const [
          Color(0xFF9B59B6),
          Color(0xFF00BCD4),
          Color(0xFF3B82F6),
          Color(0xFF9B59B6),
        ],
      ),
      AppTourStep(
        id: 'workout_step_tier_toggle',
        // Now points at the real E/A/S tier toggle (keyed in
        // workout_top_bar_v2.dart) instead of the swap area.
        targetKey: AppTourKeys.tierToggleKey,
        title: 'Switch tiers anytime',
        description:
            'Want a calmer screen? Switch to Easy from this toggle anytime.',
        position: TooltipPosition.below,
      ),
    ];

/// Single-step contextual coach-mark for the Rest Timer. Fired the first time a
/// real between-set rest begins (when the keyed inline rest row is actually on
/// screen), NOT as part of the upfront tour. See
/// `WorkoutTourService.maybeShowRestCoachmark`.
List<AppTourStep> restCoachmarkSteps() => [
      AppTourStep(
        id: 'workout_rest_coachmark',
        targetKey: AppTourKeys.restTimerKey,
        title: 'Rest Timer',
        description:
            "Starts automatically between sets. Skip it whenever you're ready to go again.",
        position: TooltipPosition.below,
      ),
    ];

/// Returns the canonical step list for the given tier.
List<AppTourStep> stepsForTier(WorkoutUiMode tier) => switch (tier) {
      WorkoutUiMode.easy => easyTourSteps(),
      // ignore: deprecated_member_use_from_same_package
      WorkoutUiMode.simple => easyTourSteps(),
      WorkoutUiMode.advanced => advancedTourSteps(),
    };

/// Fire-once-per-tier tour service.
///
/// Owns the canonical `tour_seen_<tier>` SharedPreferences flags. The
/// [AppTourController] handles visual presentation; this service decides
/// whether a tour should fire for the current tier and marks it seen after
/// dismissal.
class WorkoutTourService {
  WorkoutTourService._();

  /// Check whether the tour for [tier] has already been seen.
  static Future<bool> hasSeen(WorkoutUiMode tier) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKeyForTier(tier)) ?? false;
  }

  /// Mark [tier]'s tour as seen. Idempotent.
  static Future<void> markSeen(WorkoutUiMode tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKeyForTier(tier), true);
    debugPrint('✅ [WorkoutTour] Marked ${tier.asString} tour as seen');
  }

  /// Clear the seen flag for [tier] — used by the "Replay Tutorials" row in
  /// Settings to let users watch a tier's tour again.
  static Future<void> resetSeen(WorkoutUiMode tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKeyForTier(tier));
    // Also clear the controller's mirror flag so a re-fire isn't short-
    // circuited by the controller's own checkAndShow precheck.
    await prefs.remove('has_seen_${tourIdForTier(tier)}');
  }

  /// Entry point called from active-workout screens' `initState` post-frame
  /// callback. If the current tier's tour hasn't been seen, kicks it off.
  /// Otherwise a no-op.
  static Future<void> maybeShowForTier(
    WidgetRef ref,
    WorkoutUiMode tier,
  ) async {
    final alreadySeen = await hasSeen(tier);
    if (alreadySeen) {
      debugPrint('🔍 [WorkoutTour] ${tier.asString} already seen, skipping');
      return;
    }

    final controller = ref.read(appTourControllerProvider.notifier);
    final current = ref.read(appTourControllerProvider);
    // If another tour is already running, don't stomp it — the current tour
    // will finish and, if the user is still on this screen, this method will
    // be re-invoked on the next rebuild.
    if (current.isVisible) {
      debugPrint(
        '🔍 [WorkoutTour] Another tour is visible (${current.tourId}), deferring',
      );
      return;
    }

    final steps = stepsForTier(tier);
    debugPrint(
      '🎯 [WorkoutTour] Firing ${tier.asString} tour (${steps.length} steps)',
    );
    controller.show(tourIdForTier(tier), steps);
  }

  /// SharedPreferences flag for the one-time Rest Timer coach-mark.
  static const String _restCoachmarkSeenKey = 'tour_seen_rest_coachmark';
  static const String _restCoachmarkTourId = 'workout_rest_coachmark';

  /// Contextual Rest Timer coach-mark. Call this the first moment a real
  /// between-set rest starts (so the keyed inline rest row is mounted). Shows a
  /// single-step spotlight on the actual rest timer exactly once per user, then
  /// records it as seen. No-op if already seen or another tour is visible.
  static Future<void> maybeShowRestCoachmark(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_restCoachmarkSeenKey) ?? false) return;

    final current = ref.read(appTourControllerProvider);
    // Don't stomp an in-flight tour (e.g. the upfront tier walkthrough). The
    // next rest will re-invoke this; the seen flag isn't written until it
    // actually shows.
    if (current.isVisible) {
      debugPrint(
        '🔍 [WorkoutTour] rest coach-mark deferred (${current.tourId} visible)',
      );
      return;
    }

    await prefs.setBool(_restCoachmarkSeenKey, true);
    debugPrint('🎯 [WorkoutTour] Firing Rest Timer coach-mark');
    ref
        .read(appTourControllerProvider.notifier)
        .show(_restCoachmarkTourId, restCoachmarkSteps());
  }

  /// Clear the Rest Timer coach-mark seen flag — used by "Replay Tutorials".
  static Future<void> resetRestCoachmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restCoachmarkSeenKey);
    await prefs.remove('has_seen_$_restCoachmarkTourId');
  }

  /// Abort any in-flight tier tour (Easy/Simple/Advanced) without marking it
  /// seen. Called when the user flips tiers mid-tour so we can re-fire the
  /// new tier's walkthrough from step 1.
  ///
  /// Returns the tier whose tour was aborted, or null if no tier tour was
  /// active. Unrelated tours (nav/nutrition/etc.) are left alone.
  static WorkoutUiMode? abortIfTierTourRunning(WidgetRef ref) {
    // Callers fire this from teardown paths (tier-switch, screen pop) where
    // the WidgetRef can already be invalidated. Catch the resulting "Cannot
    // use ref after the widget was disposed" so it never escalates to a
    // fatal Crashlytics event — the tour will simply not be aborted, which
    // is harmless (worst case the next tier-switch handles it).
    try {
      final current = ref.read(appTourControllerProvider);
      if (!current.isVisible) return null;
      final tier = _tierForTourId(current.tourId);
      if (tier == null) return null;
      // Use the controller's non-persisting abort hatch so no seen flag is
      // written — the user hasn't finished, they just changed tiers.
      ref.read(appTourControllerProvider.notifier).abort();
      debugPrint(
        '⚠️ [WorkoutTour] Aborted in-flight ${tier.asString} tour (user changed tier)',
      );
      return tier;
    } catch (e) {
      debugPrint('⚠️ [WorkoutTour] abortIfTierTourRunning skipped (ref disposed): $e');
      return null;
    }
  }
}

/// Wires the AppTourController's state transitions to the canonical
/// `tour_seen_<tier>` SharedPreferences flag.
///
/// When a tier tour ends via the controller's [AppTourController.dismiss]
/// path (user taps "Got it" on the last step, or "Skip"), the controller
/// writes `has_seen_<tourId>`. This listener mirrors that into the canonical
/// `tour_seen_<tier>` key. When the tour ends via [AppTourController.abort]
/// (tier-switch mid-tour), the controller does NOT write `has_seen_...`, so
/// our mirror check correctly no-ops and the new tier's tour remains eligible.
///
/// Attach once per active-workout screen in `initState` and invoke the
/// returned subscription's `close()` in `dispose()`.
class WorkoutTourSeenListener {
  WorkoutTourSeenListener._();

  /// Installs the listener. Returns a [ProviderSubscription] so the caller
  /// can close it on `dispose()`.
  static ProviderSubscription<AppTourState> attach(WidgetRef ref) {
    return ref.listenManual<AppTourState>(
      appTourControllerProvider,
      (previous, next) async {
        // Only act on visible → invisible transitions.
        final wasVisible = previous?.isVisible ?? false;
        if (wasVisible && !next.isVisible) {
          final endedTourId = previous?.tourId;
          final tier = _tierForTourId(endedTourId);
          if (tier == null) return; // not a tier tour

          // Was the exit via dismiss() (user finished or skipped)? If so,
          // the controller has already written `has_seen_<tourId>`. If it's
          // via abort() (tier-switch), that key is NOT set and we do not
          // persist. Schedule a microtask-delayed read so dismiss()'s async
          // SharedPreferences write has a chance to land first.
          await Future<void>.delayed(Duration.zero);
          final prefs = await SharedPreferences.getInstance();
          final controllerWroteSeen =
              prefs.getBool('has_seen_$endedTourId') ?? false;
          if (!controllerWroteSeen) {
            if (kDebugMode) {
              debugPrint(
                '🔍 [WorkoutTour] Tour ended without dismiss() '
                '(likely abort) — not marking ${tier.asString} seen',
              );
            }
            return;
          }
          await WorkoutTourService.markSeen(tier);
        }
      },
      fireImmediately: false,
    );
  }
}
