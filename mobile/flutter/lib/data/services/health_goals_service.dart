import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Per-user activity / sleep targets, mirroring the backend `health_goals`
/// row (migration 2088) and the `GET`/`PUT /activity/health-goals/{uid}`
/// contract.
///
/// The Sleep detail screen sets [sleepDurationGoalMinutes]; the Combined
/// Health hub sets [stepGoal] and [activeMinutesGoal]. A user who has never
/// saved goals reads the backend contract defaults (10000 / 30 / 480 / null).
@immutable
class HealthGoals {
  final int stepGoal;
  final int activeMinutesGoal;
  final int sleepDurationGoalMinutes;

  /// Target bedtime as a `HH:MM` user-local time string, or null when unset.
  final String? bedtimeGoal;

  const HealthGoals({
    this.stepGoal = 10000,
    this.activeMinutesGoal = 30,
    this.sleepDurationGoalMinutes = 480,
    this.bedtimeGoal,
  });

  /// The contract defaults — also what every read falls back to on error so
  /// the goal-setting UI never shows a blank or fabricated value.
  static const HealthGoals defaults = HealthGoals();

  factory HealthGoals.fromJson(Map<String, dynamic> json) => HealthGoals(
        stepGoal: (json['step_goal'] as num?)?.toInt() ?? 10000,
        activeMinutesGoal:
            (json['active_minutes_goal'] as num?)?.toInt() ?? 30,
        sleepDurationGoalMinutes:
            (json['sleep_duration_goal_minutes'] as num?)?.toInt() ?? 480,
        bedtimeGoal: json['bedtime_goal'] as String?,
      );

  HealthGoals copyWith({
    int? stepGoal,
    int? activeMinutesGoal,
    int? sleepDurationGoalMinutes,
    String? bedtimeGoal,
  }) =>
      HealthGoals(
        stepGoal: stepGoal ?? this.stepGoal,
        activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
        sleepDurationGoalMinutes:
            sleepDurationGoalMinutes ?? this.sleepDurationGoalMinutes,
        bedtimeGoal: bedtimeGoal ?? this.bedtimeGoal,
      );

  @override
  bool operator ==(Object other) =>
      other is HealthGoals &&
      other.stepGoal == stepGoal &&
      other.activeMinutesGoal == activeMinutesGoal &&
      other.sleepDurationGoalMinutes == sleepDurationGoalMinutes &&
      other.bedtimeGoal == bedtimeGoal;

  @override
  int get hashCode => Object.hash(
      stepGoal, activeMinutesGoal, sleepDurationGoalMinutes, bedtimeGoal);
}

/// Thin client for the `health_goals` endpoints.
class HealthGoalsService {
  final ApiClient _apiClient;

  HealthGoalsService(this._apiClient);

  /// `GET /activity/health-goals/{uid}` — the saved row or contract
  /// defaults. Throws on a network error so a goal screen surfaces the
  /// failure instead of silently showing defaults as if they were saved.
  Future<HealthGoals> getGoals(String userId) async {
    final response = await _apiClient.get('/activity/health-goals/$userId');
    if (response.statusCode == 200 && response.data != null) {
      return HealthGoals.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to load health goals (${response.statusCode})');
  }

  /// `PUT /activity/health-goals/{uid}` — patch one or more targets. The
  /// backend fills any omitted field from the existing row, so callers send
  /// only what changed. Returns the saved row.
  Future<HealthGoals> updateGoals(
    String userId, {
    int? stepGoal,
    int? activeMinutesGoal,
    int? sleepDurationGoalMinutes,
    String? bedtimeGoal,
  }) async {
    final body = <String, dynamic>{};
    if (stepGoal != null) body['step_goal'] = stepGoal;
    if (activeMinutesGoal != null) {
      body['active_minutes_goal'] = activeMinutesGoal;
    }
    if (sleepDurationGoalMinutes != null) {
      body['sleep_duration_goal_minutes'] = sleepDurationGoalMinutes;
    }
    if (bedtimeGoal != null) body['bedtime_goal'] = bedtimeGoal;

    final response = await _apiClient.put(
      '/activity/health-goals/$userId',
      data: body,
    );
    if (response.statusCode == 200 && response.data != null) {
      return HealthGoals.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to save health goals (${response.statusCode})');
  }
}

final healthGoalsServiceProvider = Provider<HealthGoalsService>((ref) {
  return HealthGoalsService(ref.watch(apiClientProvider));
});

/// Resolves the current user id then loads their health goals.
///
/// Cache-cheap [FutureProvider]; `ref.invalidate(healthGoalsProvider)` after
/// a PUT re-reads the saved row so the UI reflects the new target.
final healthGoalsProvider = FutureProvider<HealthGoals>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return HealthGoals.defaults;
  try {
    return await ref.watch(healthGoalsServiceProvider).getGoals(userId);
  } catch (e) {
    debugPrint('⚠️ [HealthGoals] load failed, using defaults: $e');
    return HealthGoals.defaults;
  }
});
