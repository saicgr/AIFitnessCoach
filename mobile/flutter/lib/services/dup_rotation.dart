import 'package:shared_preferences/shared_preferences.dart';

import 'mesocycle_planner.dart';

/// Daily Undulating Periodization (DUP) rotation.
///
/// Cycles through Hypertrophy -> Power -> Strength on successive sessions.
/// Based on Zourdos et al. 2016 -- DUP produces superior strength and
/// hypertrophy gains compared to linear periodization.
///
/// Recovery-aware overrides:
/// - Avg recovery < 50% -> forces endurance (deload)
/// - Avg recovery < 60% -> forces power (lower volume)
///
/// Mesocycle integration:
/// - If a mesocycle is active, its primary goal overrides DUP rotation.
/// - Deload phase forces 'endurance' goal.
class DupRotation {
  static const _prefsKey = 'quick_workout_dup_last_goal';
  static const _prefsCountKey = 'quick_workout_dup_session_count';

  /// The HPS rotation order.
  static const List<String> _rotation = ['hypertrophy', 'power', 'strength'];

  /// Get the next suggested goal based on DUP rotation.
  ///
  /// [avgRecoveryPercent] - average recovery score across all muscles (0-100).
  /// If null, no recovery override is applied.
  ///
  /// If a mesocycle is active, its goal overrides DUP rotation.
  /// Deload phase forces 'endurance'.
  static Future<String> getNextGoal({double? avgRecoveryPercent}) async {
    // Mesocycle override: if active, use mesocycle's primary goal
    final mesocyclePlan = await MesocyclePlanner.getActivePlan();
    if (mesocyclePlan != null) {
      final context = await MesocyclePlanner.getCurrentContext();
      if (context != null) {
        if (context.isDeload) return 'endurance';
        return mesocyclePlan.primaryGoal;
      }
    }

    // Recovery overrides
    if (avgRecoveryPercent != null) {
      if (avgRecoveryPercent < 50) return 'endurance';
      if (avgRecoveryPercent < 60) return 'power';
    }

    final prefs = await SharedPreferences.getInstance();
    final lastGoal = prefs.getString(_prefsKey);

    if (lastGoal == null) return 'hypertrophy'; // First session

    final lastIdx = _rotation.indexOf(lastGoal);
    if (lastIdx == -1) return 'hypertrophy'; // Unknown goal, reset

    final nextIdx = (lastIdx + 1) % _rotation.length;
    return _rotation[nextIdx];
  }

  /// Record that a session was completed with the given goal.
  static Future<void> recordSession(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, goal.toLowerCase());
    final count = prefs.getInt(_prefsCountKey) ?? 0;
    await prefs.setInt(_prefsCountKey, count + 1);
  }

  /// Get the total number of DUP sessions completed.
  static Future<int> getSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsCountKey) ?? 0;
  }

  /// Get the last recorded goal (for display purposes).
  static Future<String?> getLastGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }
}
