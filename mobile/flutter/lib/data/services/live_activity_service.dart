/// Live workout surface for iOS (Dynamic Island / Lock Screen Live Activity)
/// and Android (ongoing notification with chronometer + progress).
///
/// iOS path: `live_activities` pub.dev package (requires Widget Extension
/// target in Xcode — see docs/live_activity_xcode_setup.md).
/// Android path: delegates to [WorkoutNotificationService] which uses
/// `flutter_local_notifications` with a native chronometer.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/feature_flags.dart';
import 'workout_notification_service.dart';

/// Immutable snapshot of the state we surface to the Live Activity / notification.
class WorkoutActivityState {
  const WorkoutActivityState({
    required this.workoutName,
    required this.currentExercise,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.currentSet,
    required this.totalSets,
    required this.isResting,
    required this.restEndsAt,
    required this.isPaused,
    required this.startedAt,
    required this.pausedDurationSeconds,
  });

  final String workoutName;
  final String currentExercise;
  final int currentExerciseIndex; // 1-based
  final int totalExercises;
  final int currentSet; // 1-based
  final int totalSets;
  final bool isResting;
  final DateTime? restEndsAt;
  final bool isPaused;
  final DateTime startedAt;
  final int pausedDurationSeconds;

  /// Payload for the `live_activities` package. Values kept as strings so
  /// SwiftUI can parse them consistently via UserDefaults.
  Map<String, dynamic> toPackagePayload() => <String, dynamic>{
        'workoutName': workoutName,
        'currentExercise': currentExercise,
        'currentExerciseIndex': '$currentExerciseIndex',
        'totalExercises': '$totalExercises',
        'currentSet': '$currentSet',
        'totalSets': '$totalSets',
        'isResting': '$isResting',
        'restEndsAtEpochMs':
            '${restEndsAt?.millisecondsSinceEpoch ?? 0}',
        'isPaused': '$isPaused',
        'startedAtEpochMs': '${startedAt.millisecondsSinceEpoch}',
        'pausedDurationSeconds': '$pausedDurationSeconds',
      };
}

/// Singleton that owns the lifecycle of the workout Live Activity.
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  // App Group shared with the FitWizLiveActivity Widget Extension.
  static const String _appGroupId = 'group.fitwiz.liveactivity';

  // Apple limits Live Activities to 8 hours. End one slightly before.
  static const Duration _maxDuration = Duration(hours: 7, minutes: 55);

  final LiveActivities _iosPlugin = LiveActivities();
  static const _uuid = Uuid();

  bool _initialized = false;
  String? _iosActivityId;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _maxDurationTimer;

  /// Call once at app startup (alongside Firebase / notification init).
  /// Clears orphan iOS activities from a prior (possibly crashed) session.
  Future<void> init() async {
    if (_initialized) return;
    if (!kUseLiveActivityService) {
      _initialized = true;
      return;
    }

    if (Platform.isIOS) {
      try {
        // Personal Teams cannot use Push Notifications capability, so we
        // skip notification permission. This disables push-driven updates
        // (which we don't use anyway — all updates are local).
        await _iosPlugin.init(
          appGroupId: _appGroupId,
          requireNotificationPermission: false,
        );
        final existing = await _iosPlugin.getAllActivitiesIds();
        for (final id in existing) {
          try {
            await _iosPlugin.endActivity(id);
          } catch (e) {
            debugPrint('⚠️ [LiveActivity] Failed ending orphan $id: $e');
          }
        }
        debugPrint(
            '🎯 [LiveActivity] iOS init complete; cleared ${existing.length} orphan(s)');
      } catch (e, st) {
        debugPrint('❌ [LiveActivity] iOS init failed: $e\n$st');
      }
    } else if (Platform.isAndroid) {
      await WorkoutNotificationService.instance.initialize();
    }

    _initialized = true;
  }

  /// Start a new Live Activity for the current workout.
  /// Idempotent: if already started, ends the prior one first.
  Future<void> start(WorkoutActivityState state) async {
    if (!kUseLiveActivityService) return;
    if (!_initialized) await init();

    // Defensive — clear any previous activity before starting a new one.
    if (_iosActivityId != null || _maxDurationTimer != null) {
      await end();
    }

    _scheduleMaxDurationSafety();

    if (Platform.isIOS) {
      try {
        final enabled = await _iosPlugin.areActivitiesEnabled();
        if (!enabled) {
          debugPrint(
              '⚠️ [LiveActivity] User disabled Live Activities in Settings — skipping');
          return;
        }
        final activityId = _uuid.v4();
        final created = await _iosPlugin.createActivity(
          activityId,
          state.toPackagePayload(),
          removeWhenAppIsKilled: true,
        );
        _iosActivityId = created ?? activityId;
        debugPrint('✅ [LiveActivity] iOS activity started: $_iosActivityId');
      } on PlatformException catch (e) {
        debugPrint('❌ [LiveActivity] iOS start failed: ${e.message}');
      } catch (e) {
        debugPrint('❌ [LiveActivity] iOS start failed: $e');
      }
    } else if (Platform.isAndroid) {
      await _showAndroid(state);
    }
  }

  /// Update the live surface with new state. Throttled to one call per
  /// second (iOS 18 enforces 5-15s updates server-side anyway, and the
  /// native chronometer / `Text(timerInterval:)` handles ticking itself).
  Future<void> update(WorkoutActivityState state) async {
    if (!kUseLiveActivityService) return;
    if (!_initialized) return;

    final now = DateTime.now();
    if (now.difference(_lastUpdate) < const Duration(seconds: 1)) return;
    _lastUpdate = now;

    try {
      if (Platform.isIOS) {
        if (_iosActivityId == null) return;
        await _iosPlugin.updateActivity(
            _iosActivityId!, state.toPackagePayload());
      } else if (Platform.isAndroid) {
        await _showAndroid(state);
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ [LiveActivity] update failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [LiveActivity] update failed: $e');
    }
  }

  /// End the current Live Activity. Safe to call multiple times.
  Future<void> end() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    if (!kUseLiveActivityService) return;

    try {
      if (Platform.isIOS && _iosActivityId != null) {
        await _iosPlugin.endActivity(_iosActivityId!);
        debugPrint('🎯 [LiveActivity] iOS activity ended: $_iosActivityId');
        _iosActivityId = null;
      } else if (Platform.isAndroid) {
        await WorkoutNotificationService.instance.cancel();
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ [LiveActivity] end failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [LiveActivity] end failed: $e');
    }
  }

  bool get isActive =>
      _iosActivityId != null ||
      (Platform.isAndroid && WorkoutNotificationService.instance.isShowing);

  // ---------------------------------------------------------------------------
  // Android helper — delegate to WorkoutNotificationService with rich state
  // ---------------------------------------------------------------------------

  Future<void> _showAndroid(WorkoutActivityState state) async {
    final timerText = state.isResting && state.restEndsAt != null
        ? 'Resting · ${_formatRemaining(state.restEndsAt!)}'
        : _formatElapsed(state);

    // Anchor Android's native chronometer to the wall-clock start (minus
    // any paused time). When resting, suppress chronometer so the subText
    // shows the rest countdown instead of irrelevant elapsed time.
    final chronometerAnchor = state.isResting
        ? null
        : state.startedAt
            .add(Duration(seconds: state.pausedDurationSeconds));

    await WorkoutNotificationService.instance.show(
      workoutName: state.workoutName,
      currentExerciseName: state.currentExercise,
      timerText: timerText,
      exerciseProgress:
          'Set ${state.currentSet}/${state.totalSets} · Ex ${state.currentExerciseIndex}/${state.totalExercises}',
      isPaused: state.isPaused,
      startedAt: chronometerAnchor,
      completedExercises: state.currentExerciseIndex - 1,
      totalExercises: state.totalExercises,
    );
  }

  String _formatElapsed(WorkoutActivityState state) {
    final elapsed =
        DateTime.now().difference(state.startedAt).inSeconds -
            state.pausedDurationSeconds;
    final safe = elapsed < 0 ? 0 : elapsed;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatRemaining(DateTime endsAt) {
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    final safe = remaining < 0 ? 0 : remaining;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _scheduleMaxDurationSafety() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(_maxDuration, () {
      debugPrint(
          '🎯 [LiveActivity] 7h55m safety timer fired — ending activity before 8h cap');
      end();
    });
  }
}
