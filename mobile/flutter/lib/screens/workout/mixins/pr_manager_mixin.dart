import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/pr_detection_service.dart';
import '../models/workout_state.dart';
import '../widgets/pr_inline_celebration.dart';

/// Mixin providing PR (Personal Record) detection and celebration
/// functionality for the active workout screen.
mixin PRManagerMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  PRDetectionService get prDetectionService;
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  Map<int, List<SetLog>> get completedSets;

  // ── PR Detection ──

  /// Preload exercise history for PR comparison
  Future<void> preloadPRHistory(dynamic ref) async {
    try {
      await prDetectionService.preloadExerciseHistory(
        ref: ref,
        exercises: exercises,
      );
      debugPrint('✅ [PR] Preloaded exercise history for PR detection');
    } catch (e) {
      debugPrint('❌ [PR] Error preloading PR history: $e');
    }
  }

  /// Check for PRs after completing a set
  void checkForPRs(SetLog setLog, WorkoutExercise exercise) {
    final sets = completedSets[currentExerciseIndex] ?? [];
    double totalVolume = 0;
    for (final set in sets) {
      totalVolume += set.weight * set.reps;
    }

    final detectedPRs = prDetectionService.checkForPR(
      exerciseName: exercise.name,
      weight: setLog.weight,
      reps: setLog.reps,
      totalSets: sets.length,
      totalVolume: totalVolume,
    );

    // Even when no all-time PR fires, give a small celebration when this
    // set out-lifts the prior set in the same exercise — keeps progressive
    // overload feeling rewarding without spamming the full PR overlay.
    if (detectedPRs.isEmpty) {
      _maybeShowProgressionMicroCelebration(setLog, sets);
      return;
    }

    debugPrint('🏆 [PR] Detected ${detectedPRs.length} PR(s)!');

    prDetectionService.triggerHaptics(detectedPRs);

    bool celebrated = false;
    for (final pr in detectedPRs) {
      if (prDetectionService.shouldShowCelebration(pr)) {
        prDetectionService.recordCelebration();
        prDetectionService.updateCacheAfterPR(pr);

        if (detectedPRs.length > 1) {
          _showMultiPRCelebration(detectedPRs);
        } else {
          _showSinglePRCelebration(pr);
        }
        celebrated = true;
        break;
      }
    }
    // PR was detected but suppressed by cooldown/cap → still acknowledge
    // the within-workout progression so the user gets feedback.
    if (!celebrated) {
      _maybeShowProgressionMicroCelebration(setLog, sets);
    }
  }

  /// Compare the just-logged set to the previous set of the same exercise.
  /// Show a small floating chip + light haptic when it's a step up
  /// (heavier load, or same load with more reps).
  void _maybeShowProgressionMicroCelebration(
    SetLog setLog,
    List<SetLog> setsAfter,
  ) {
    if (setsAfter.length < 2) return;
    final prev = setsAfter[setsAfter.length - 2];
    final beatsWeight = setLog.weight > prev.weight + 0.05;
    final matchesAndBeatsReps =
        (setLog.weight - prev.weight).abs() < 0.05 && setLog.reps > prev.reps;
    if (!beatsWeight && !matchesAndBeatsReps) return;
    if (setLog.weight <= 0 || setLog.reps <= 0) return;

    HapticService.success();

    final String label;
    if (beatsWeight) {
      label = 'Heavier set 💪';
    } else {
      final delta = setLog.reps - prev.reps;
      label = '+$delta rep${delta == 1 ? '' : 's'} 💪';
    }
    _showProgressionChip(label);
  }

  void _showProgressionChip(String label) {
    if (!mounted) return;
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ProgressionChipOverlay(
        label: label,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlayState.insert(entry);
  }

  /// Show single PR inline celebration
  void _showSinglePRCelebration(DetectedPR pr) {
    showPRInlineCelebration(
      context: context,
      pr: pr,
      onDismiss: () {
        debugPrint('✨ [PR] Celebration dismissed');
      },
    );
  }

  /// Show multi-PR celebration
  void _showMultiPRCelebration(List<DetectedPR> prs) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => MultiPRInlineCelebration(
        prs: prs,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// Small floating chip shown above the active-workout content when a logged
/// set beats the prior set's weight or reps. Auto-dismisses after ~1.4s.
/// Lives in this file (not a widget folder) because it's only ever spawned
/// by [PRManagerMixin] and doesn't compose with anything else.
class _ProgressionChipOverlay extends StatefulWidget {
  final String label;
  final VoidCallback onDone;

  const _ProgressionChipOverlay({
    required this.label,
    required this.onDone,
  });

  @override
  State<_ProgressionChipOverlay> createState() =>
      _ProgressionChipOverlayState();
}

class _ProgressionChipOverlayState extends State<_ProgressionChipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 1200), _reverseAndDone);
  }

  Future<void> _reverseAndDone() async {
    if (!mounted) return;
    await _c.reverse();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: mq.padding.top + 60,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
