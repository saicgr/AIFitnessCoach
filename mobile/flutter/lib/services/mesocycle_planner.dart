import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'rpe_feedback_service.dart';
import 'volume_landmark_service.dart';

/// Phase within a mesocycle block.
enum MesocyclePhase {
  /// Weeks 1-2: Start at MEV, +2 sets/muscle/week. RPE target 6-7.
  rampUp,

  /// Weeks 3-4/5: Push toward MRV. RPE target 8-9. +2.5% intensity/week.
  overreach,

  /// Final week: 50% of MAV. RPE target 5-6. Intensity * 0.85.
  deload,
}

/// Context passed to the quick workout engine for mesocycle-aware generation.
class MesocycleContext {
  final MesocyclePhase phase;
  final int weekNumber;
  final int totalWeeks;

  /// Target weekly sets per muscle (adjusted for current week).
  final Map<String, int> targetWeeklySets;

  /// Intensity multiplier for the current phase/week.
  final double intensityMultiplier;

  /// Target RPE range [min, max] for the current phase.
  final (double min, double max) rpeTargetRange;

  /// Primary training goal for this mesocycle.
  final String primaryGoal;

  const MesocycleContext({
    required this.phase,
    required this.weekNumber,
    required this.totalWeeks,
    required this.targetWeeklySets,
    required this.intensityMultiplier,
    required this.rpeTargetRange,
    required this.primaryGoal,
  });

  String get phaseDisplayName {
    switch (phase) {
      case MesocyclePhase.rampUp:
        return 'Ramp Up';
      case MesocyclePhase.overreach:
        return 'Overreach';
      case MesocyclePhase.deload:
        return 'Deload';
    }
  }

  bool get isDeload => phase == MesocyclePhase.deload;
}

/// Stored mesocycle plan.
class MesocyclePlan {
  final String id;
  final String primaryGoal;
  final int totalWeeks;
  final int currentWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  const MesocyclePlan({
    required this.id,
    required this.primaryGoal,
    required this.totalWeeks,
    required this.currentWeek,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'primaryGoal': primaryGoal,
        'totalWeeks': totalWeeks,
        'currentWeek': currentWeek,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
      };

  factory MesocyclePlan.fromJson(Map<String, dynamic> json) {
    return MesocyclePlan(
      id: json['id'] as String,
      primaryGoal: json['primaryGoal'] as String,
      totalWeeks: json['totalWeeks'] as int,
      currentWeek: json['currentWeek'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  MesocyclePlan copyWith({
    int? currentWeek,
    bool? isActive,
    DateTime? endDate,
  }) {
    return MesocyclePlan(
      id: id,
      primaryGoal: primaryGoal,
      totalWeeks: totalWeeks,
      currentWeek: currentWeek ?? this.currentWeek,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Mesocycle planning service for multi-week progressive structure.
///
/// A mesocycle is a 4-6 week training block with three phases:
/// - **Ramp Up** (weeks 1-2): Start at MEV, +2 sets/muscle/week. RPE 6-7.
/// - **Overreach** (weeks 3-4/5): Push toward MRV. RPE 8-9. +2.5%/week.
/// - **Deload** (final week): 50% of MAV. RPE 5-6. Intensity * 0.85.
class MesocyclePlanner {
  static const _activePlanKey = 'mesocycle_active_plan';
  static const _historyKey = 'mesocycle_history';

  /// Get the currently active mesocycle plan, if any.
  static Future<MesocyclePlan?> getActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activePlanKey);
    if (raw == null) return null;

    try {
      final plan = MesocyclePlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!plan.isActive) return null;

      // Auto-advance week based on elapsed time
      final weeksElapsed =
          DateTime.now().difference(plan.startDate).inDays ~/ 7;
      final effectiveWeek = (weeksElapsed + 1).clamp(1, plan.totalWeeks);

      if (effectiveWeek > plan.totalWeeks) {
        // Mesocycle completed - deactivate
        await _completePlan(plan);
        return null;
      }

      if (effectiveWeek != plan.currentWeek) {
        final updated = plan.copyWith(currentWeek: effectiveWeek);
        await _savePlan(updated);
        return updated;
      }

      return plan;
    } catch (_) {
      return null;
    }
  }

  /// Create a new mesocycle plan.
  ///
  /// [totalWeeks] must be 4-6 (defaults to 5: 2 ramp + 2 overreach + 1 deload).
  static Future<MesocyclePlan> createPlan({
    required String primaryGoal,
    int totalWeeks = 5,
  }) async {
    final clamped = totalWeeks.clamp(4, 6);
    final plan = MesocyclePlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      primaryGoal: primaryGoal,
      totalWeeks: clamped,
      currentWeek: 1,
      startDate: DateTime.now(),
    );

    await _savePlan(plan);
    return plan;
  }

  /// Get mesocycle context for the current week.
  ///
  /// Returns null if no active mesocycle.
  static Future<MesocycleContext?> getCurrentContext({
    Map<String, VolumeLandmarks> volumeLandmarks = const {},
  }) async {
    final plan = await getActivePlan();
    if (plan == null) return null;

    final phase = _getPhase(plan.currentWeek, plan.totalWeeks);
    final intensity = _getIntensityMultiplier(phase, plan.currentWeek);
    final rpeRange = _getRpeTargetRange(phase);
    final targetSets =
        _computeTargetWeeklySets(phase, plan.currentWeek, volumeLandmarks);

    return MesocycleContext(
      phase: phase,
      weekNumber: plan.currentWeek,
      totalWeeks: plan.totalWeeks,
      targetWeeklySets: targetSets,
      intensityMultiplier: intensity,
      rpeTargetRange: rpeRange,
      primaryGoal: plan.primaryGoal,
    );
  }

  /// Check auto-deload triggers and force deload if needed.
  ///
  /// Triggers:
  /// - 3+ exercises with avgRpe > 9.5
  /// - Average recovery < 50%
  /// - 2+ exercises with `deload` decision
  static Future<bool> shouldAutoDeload({
    required Map<String, ExerciseRpeSummary> rpeSummaries,
    required Map<String, double> recoveryScores,
  }) async {
    // Check RPE trigger: 3+ exercises at avgRpe > 9.5
    final highRpeCount = rpeSummaries.values
        .where((s) => s.avgRpe > 9.5 && s.sessionCount >= 2)
        .length;
    if (highRpeCount >= 3) return true;

    // Check recovery trigger: average < 50%
    if (recoveryScores.isNotEmpty) {
      final avgRecovery =
          recoveryScores.values.reduce((a, b) => a + b) / recoveryScores.length;
      if (avgRecovery < 50) return true;
    }

    // Check deload decision trigger: 2+ exercises
    final deloadCount = rpeSummaries.values
        .where((s) => s.decision == RpeDecision.deload)
        .length;
    if (deloadCount >= 2) return true;

    return false;
  }

  /// Force the current mesocycle into deload phase.
  static Future<void> forceDeload() async {
    final plan = await getActivePlan();
    if (plan == null) return;

    // Set current week to the last week (deload)
    final updated = plan.copyWith(currentWeek: plan.totalWeeks);
    await _savePlan(updated);
  }

  /// Advance to next week manually.
  static Future<void> advanceWeek() async {
    final plan = await getActivePlan();
    if (plan == null) return;

    final nextWeek = plan.currentWeek + 1;
    if (nextWeek > plan.totalWeeks) {
      await _completePlan(plan);
    } else {
      await _savePlan(plan.copyWith(currentWeek: nextWeek));
    }
  }

  /// Complete the current mesocycle.
  static Future<void> completeMesocycle() async {
    final plan = await getActivePlan();
    if (plan == null) return;
    await _completePlan(plan);
  }

  /// Get mesocycle history.
  static Future<List<MesocyclePlan>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => MesocyclePlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────

  static MesocyclePhase _getPhase(int week, int totalWeeks) {
    if (week >= totalWeeks) return MesocyclePhase.deload;
    if (week <= 2) return MesocyclePhase.rampUp;
    return MesocyclePhase.overreach;
  }

  static double _getIntensityMultiplier(MesocyclePhase phase, int week) {
    switch (phase) {
      case MesocyclePhase.rampUp:
        return 1.0;
      case MesocyclePhase.overreach:
        // +2.5% per week starting from week 3
        return 1.0 + (week - 2) * 0.025;
      case MesocyclePhase.deload:
        return 0.85;
    }
  }

  static (double, double) _getRpeTargetRange(MesocyclePhase phase) {
    switch (phase) {
      case MesocyclePhase.rampUp:
        return (6.0, 7.0);
      case MesocyclePhase.overreach:
        return (8.0, 9.0);
      case MesocyclePhase.deload:
        return (5.0, 6.0);
    }
  }

  /// Compute target weekly sets per muscle for the current phase/week.
  ///
  /// - Ramp: MEV + (week-1) * 2
  /// - Overreach: continue up, cap at MRV
  /// - Deload: MAV * 0.5
  static Map<String, int> _computeTargetWeeklySets(
    MesocyclePhase phase,
    int week,
    Map<String, VolumeLandmarks> landmarks,
  ) {
    final result = <String, int>{};

    for (final entry in landmarks.entries) {
      final muscle = entry.key;
      final vl = entry.value;

      int target;
      switch (phase) {
        case MesocyclePhase.rampUp:
          target = vl.mev + (week - 1) * 2;
        case MesocyclePhase.overreach:
          // Continue ramping from where ramp-up left off
          target = vl.mev + (week - 1) * 2;
          if (target > vl.mrv) target = vl.mrv;
        case MesocyclePhase.deload:
          target = (vl.mav * 0.5).round();
      }

      result[muscle] = target.clamp(0, vl.mrv);
    }

    return result;
  }

  static Future<void> _savePlan(MesocyclePlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePlanKey, jsonEncode(plan.toJson()));
  }

  static Future<void> _completePlan(MesocyclePlan plan) async {
    final prefs = await SharedPreferences.getInstance();

    // Deactivate
    final completed = plan.copyWith(
      isActive: false,
      endDate: DateTime.now(),
    );

    // Add to history
    final history = await getHistory();
    history.insert(0, completed);
    // Keep last 10 mesocycles
    final trimmed = history.take(10).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );

    // Remove active plan
    await prefs.remove(_activePlanKey);
  }
}
