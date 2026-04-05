import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/exercise.dart';
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

    if (detectedPRs.isEmpty) return;

    debugPrint('🏆 [PR] Detected ${detectedPRs.length} PR(s)!');

    prDetectionService.triggerHaptics(detectedPRs);

    for (final pr in detectedPRs) {
      if (prDetectionService.shouldShowCelebration(pr)) {
        prDetectionService.recordCelebration();
        prDetectionService.updateCacheAfterPR(pr);

        if (detectedPRs.length > 1) {
          _showMultiPRCelebration(detectedPRs);
        } else {
          _showSinglePRCelebration(pr);
        }
        break;
      }
    }
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
