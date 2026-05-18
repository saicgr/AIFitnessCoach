/// Live fasting surface for iOS (Dynamic Island / Lock Screen Live Activity).
///
/// Uses the `live_activities` pub.dev package — the same package and App
/// Group (`group.zealova.liveactivity`) used by [LiveActivityService] for
/// workouts. The shared Swift Widget Extension (`FitWizLiveActivity`) reads
/// an `activityKind` discriminator key from the App Group `UserDefaults` and
/// branches between the workout and fasting layouts.
///
/// Because the `live_activities` package surfaces a single activity payload
/// per App Group, a fast and a workout are not expected to run concurrently;
/// if one is active the other should not be started. Both call
/// `endActivity` on completion.
///
/// Android has no Live Activity — the live fast surface on Android is the
/// ongoing actionable notification (see [FastingOngoingNotificationService]).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/feature_flags.dart';

/// Immutable snapshot of the fast surfaced to the Live Activity.
class FastingActivityState {
  const FastingActivityState({
    required this.protocolName,
    required this.stageName,
    required this.stageDescription,
    required this.startedAt,
    required this.goalEndsAt,
    required this.goalDurationMinutes,
    required this.isPaused,
    required this.pausedSeconds,
  });

  /// e.g. "16:8" — the fasting protocol display name.
  final String protocolName;

  /// Current metabolic stage display name, e.g. "Fat Burning".
  final String stageName;

  /// One-line description of the current stage.
  final String stageDescription;

  /// Wall-clock fast start.
  final DateTime startedAt;

  /// Wall-clock time the goal is reached (start + goal, no pause shift —
  /// the Swift side shifts by pausedSeconds).
  final DateTime goalEndsAt;

  /// Goal length in minutes.
  final int goalDurationMinutes;

  /// Whether the fast is currently paused.
  final bool isPaused;

  /// Total seconds the fast has spent paused so far.
  final int pausedSeconds;

  /// Payload for the `live_activities` package. Values kept as strings so
  /// the shared SwiftUI extension parses them consistently via UserDefaults.
  Map<String, dynamic> toPackagePayload() => <String, dynamic>{
        // Discriminator — the Swift extension branches on this.
        'activityKind': 'fasting',
        'fastProtocolName': protocolName,
        'fastStageName': stageName,
        'fastStageDescription': stageDescription,
        'fastStartedAtEpochMs': '${startedAt.millisecondsSinceEpoch}',
        'fastGoalEndsAtEpochMs': '${goalEndsAt.millisecondsSinceEpoch}',
        'fastGoalDurationMinutes': '$goalDurationMinutes',
        'fastIsPaused': '$isPaused',
        'fastPausedSeconds': '$pausedSeconds',
      };
}

/// Singleton that owns the lifecycle of the fasting Live Activity.
class FastingLiveActivityService {
  FastingLiveActivityService._();
  static final FastingLiveActivityService instance =
      FastingLiveActivityService._();

  /// App Group shared with the FitWizLiveActivity Widget Extension —
  /// identical to the one used by the workout [LiveActivityService].
  static const String _appGroupId = 'group.zealova.liveactivity';

  final LiveActivities _iosPlugin = LiveActivities();
  static const _uuid = Uuid();

  bool _initialized = false;
  String? _iosActivityId;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  /// Initialize the iOS plugin. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    if (!kUseLiveActivityService || !Platform.isIOS) {
      _initialized = true;
      return;
    }
    try {
      await _iosPlugin.init(
        appGroupId: _appGroupId,
        requireNotificationPermission: false,
      );
      _initialized = true;
      debugPrint('🕐 [FastingLiveActivity] iOS init complete');
    } catch (e, st) {
      debugPrint('❌ [FastingLiveActivity] iOS init failed: $e\n$st');
      _initialized = true; // don't retry endlessly
    }
  }

  /// Start a fasting Live Activity. Idempotent — ends any prior one first.
  Future<void> start(FastingActivityState state) async {
    if (!kUseLiveActivityService || !Platform.isIOS) return;
    if (!_initialized) await init();

    if (_iosActivityId != null) {
      await end();
    }

    try {
      final enabled = await _iosPlugin.areActivitiesEnabled();
      if (!enabled) {
        debugPrint(
            '⚠️ [FastingLiveActivity] User disabled Live Activities — skipping');
        return;
      }
      final activityId = _uuid.v4();
      final created = await _iosPlugin.createActivity(
        activityId,
        state.toPackagePayload(),
        removeWhenAppIsKilled: true,
      );
      _iosActivityId = created ?? activityId;
      debugPrint(
          '✅ [FastingLiveActivity] iOS activity started: $_iosActivityId');
    } on PlatformException catch (e) {
      debugPrint('❌ [FastingLiveActivity] start failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ [FastingLiveActivity] start failed: $e');
    }
  }

  /// Update the activity. Throttled to one call per second — the native
  /// `Text(timerInterval:)` ticks the clock itself, so updates are only
  /// needed on stage / pause changes.
  Future<void> update(FastingActivityState state) async {
    if (!kUseLiveActivityService || !Platform.isIOS) return;
    if (!_initialized || _iosActivityId == null) return;

    final now = DateTime.now();
    if (now.difference(_lastUpdate) < const Duration(seconds: 1)) return;
    _lastUpdate = now;

    try {
      await _iosPlugin.updateActivity(
          _iosActivityId!, state.toPackagePayload());
    } on PlatformException catch (e) {
      debugPrint('⚠️ [FastingLiveActivity] update failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [FastingLiveActivity] update failed: $e');
    }
  }

  /// End the fasting Live Activity. Safe to call multiple times.
  Future<void> end() async {
    if (!kUseLiveActivityService || !Platform.isIOS) return;
    try {
      if (_iosActivityId != null) {
        await _iosPlugin.endActivity(_iosActivityId!);
        debugPrint(
            '🕐 [FastingLiveActivity] iOS activity ended: $_iosActivityId');
        _iosActivityId = null;
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ [FastingLiveActivity] end failed: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [FastingLiveActivity] end failed: $e');
    }
  }

  bool get isActive => _iosActivityId != null;
}
