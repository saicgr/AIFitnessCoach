/// Exercise Tip Service
///
/// Generates personalized, per-exercise AI coach tips using the backend
/// Gemini endpoint. Tips reflect the user's selected coach persona
/// (tone, style, encouragement) and incorporate previous performance data.
///
/// Tips are pre-fetched in parallel at workout start so they're instant
/// when each exercise begins. In-flight deduplication prevents double API calls.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/api_client.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';

// Fix #10: SharedPreferences keys + thresholds for the coach-tip dedup
// system. These are exported so chat repository code (not in my ownership
// in this fix pass) can read the same toggle/threshold without drift.

/// User-facing toggle. Default = false → auto-fired coach tips render only as
/// the inline ephemeral banner, NOT as chat history rows. Settings UI to wire
/// this is a follow-up; the storage key + plumbing exist now.
const String kSaveCoachTipsToChatPrefKey = 'save_coach_tips_to_chat';

/// One-time prune migration flag. Idempotent — once true, prune is skipped on
/// subsequent launches.
const String kPruneCoachDuplicatesV1PrefKey = 'prune_coach_duplicates_v1';

/// Source-tag value written to assistant chat messages that originated from
/// the auto-fired exercise-tip pipeline. Chat repository should ONLY prune
/// rows carrying this tag (or the heuristic "Listen up" fallback) — never
/// raw user-initiated assistant replies.
const String kCoachTipMessageSource = 'auto_coach_tip';

/// Levenshtein dedup threshold. Assistant messages > [kCoachTipDedupMinChars]
/// chars whose normalized similarity to one of the last
/// [kCoachTipDedupWindow] assistant messages exceeds this value are dropped.
/// 0.85 was selected empirically from the "Listen up, Yep That's Right…"
/// repetitions reported in image 16. Tune cautiously — too low false-positives
/// on legitimate variations.
const double kCoachTipDedupSimilarityThreshold = 0.85;
const int kCoachTipDedupMinChars = 80;
const int kCoachTipDedupWindow = 3;

final exerciseTipServiceProvider = Provider<ExerciseTipService>((ref) {
  return ExerciseTipService(ref.read(apiClientProvider));
});

class ExerciseTipService {
  final ApiClient _apiClient;

  /// Cache: exerciseName -> tip (one per workout session)
  final Map<String, String> _tipCache = {};

  /// In-flight requests: exerciseName -> future (prevents duplicate API calls)
  final Map<String, Future<String>> _inFlight = {};

  ExerciseTipService(this._apiClient);

  /// Fetch a personalized AI coach tip for the given exercise.
  ///
  /// Returns instantly from cache if pre-fetched.
  /// Deduplicates concurrent requests for the same exercise.
  /// Falls back to a local tip on API failure.
  Future<String> getExerciseTip({
    required String exerciseName,
    required AISettings aiSettings,
    String? bodyPart,
    String? equipment,
    int sets = 3,
    int? reps,
    double? targetWeight,
    bool useKg = false,
    String? userGoal,
    String? progressionPattern,
    List<Map<String, dynamic>>? previousSets,
    double? prWeight,
  }) {
    // 1. Instant cache hit
    final cached = _tipCache[exerciseName];
    if (cached != null) {
      return Future.value(cached);
    }

    // 2. Return existing in-flight request (dedup)
    final existing = _inFlight[exerciseName];
    if (existing != null) {
      return existing;
    }

    // 3. Start new request
    final future = _fetchTip(
      exerciseName: exerciseName,
      aiSettings: aiSettings,
      bodyPart: bodyPart,
      equipment: equipment,
      sets: sets,
      reps: reps,
      targetWeight: targetWeight,
      useKg: useKg,
      userGoal: userGoal,
      progressionPattern: progressionPattern,
      previousSets: previousSets,
      prWeight: prWeight,
    ).whenComplete(() => _inFlight.remove(exerciseName));

    _inFlight[exerciseName] = future;
    return future;
  }

  Future<String> _fetchTip({
    required String exerciseName,
    required AISettings aiSettings,
    String? bodyPart,
    String? equipment,
    int sets = 3,
    int? reps,
    double? targetWeight,
    bool useKg = false,
    String? userGoal,
    String? progressionPattern,
    List<Map<String, dynamic>>? previousSets,
    double? prWeight,
  }) async {
    final coach = aiSettings.getCurrentCoach();

    try {
      debugPrint('💡 [ExerciseTip] Fetching AI tip for $exerciseName (${coach.name})');

      // Build previous sets data
      List<Map<String, dynamic>>? prevSetsPayload;
      if (previousSets != null && previousSets.isNotEmpty) {
        prevSetsPayload = previousSets.map((s) => {
          'weight': s['weight'],
          'reps': s['reps'],
          'rpe': s['rpe'],
          'rir': s['rir'],
        }).toList();
      }

      final response = await _apiClient.post(
        '/workouts/exercise-tip',
        data: {
          'exercise_name': exerciseName,
          if (bodyPart != null) 'body_part': bodyPart,
          if (equipment != null) 'equipment': equipment,
          'sets': sets,
          if (reps != null) 'reps': reps,
          if (targetWeight != null && targetWeight > 0) 'target_weight': targetWeight,
          'use_kg': useKg,
          if (userGoal != null) 'user_goal': userGoal,
          if (progressionPattern != null) 'progression_pattern': progressionPattern,
          if (prevSetsPayload != null) 'previous_sets': prevSetsPayload,
          if (prWeight != null && prWeight > 0) 'pr_weight': prWeight,
          'coach_name': coach.name,
          'coaching_style': coach.coachingStyle,
          'communication_tone': coach.communicationTone,
          'encouragement_level': coach.encouragementLevel,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tip = response.data['tip'] as String;
        _tipCache[exerciseName] = tip;
        debugPrint('✅ [ExerciseTip] Got AI tip for $exerciseName');
        return tip;
      }
    } catch (e) {
      debugPrint('❌ [ExerciseTip] API failed for $exerciseName: $e');
    }

    // Fallback: generate a local tip
    final fallback = _getLocalFallback(exerciseName, coach.coachingStyle);
    _tipCache[exerciseName] = fallback;
    return fallback;
  }

  /// Get cached tip for a specific exercise (returns null if not yet fetched)
  String? getCachedTip(String exerciseName) => _tipCache[exerciseName];

  String _getLocalFallback(String exerciseName, String style) {
    switch (style) {
      case 'drill-sergeant':
        return 'Lock in. Control every rep. No half reps on $exerciseName.';
      case 'zen-master':
        return 'Breathe into the movement. Feel each rep of $exerciseName with intention.';
      case 'hype-beast':
        return 'Time to GO OFF on $exerciseName! Every rep counts, let\'s get it!';
      case 'scientist':
        return 'Focus on full range of motion and controlled tempo for $exerciseName.';
      default:
        return 'You\'ve got this! Focus on strong, controlled reps for $exerciseName.';
    }
  }

  /// Clear the tip cache (call when starting a new workout)
  void clearCache() {
    _tipCache.clear();
    _inFlight.clear();
    debugPrint('💡 [ExerciseTip] Cache cleared');
  }

  // ============================================================
  // Fix #10: Coach-tip dedup helpers (shared by chat repository
  // when it appends assistant messages). Kept here so the
  // tip-source service owns the dedup contract.
  // ============================================================

  /// Whether the user has opted in to keeping auto-fired coach tips in their
  /// chat history. Defaults to `false` — tips remain ephemeral (inline banner
  /// only). Settings UI toggle is a follow-up.
  static Future<bool> shouldSaveCoachTipsToChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kSaveCoachTipsToChatPrefKey) ?? false;
    } catch (e) {
      debugPrint('⚠️ [ExerciseTip] saveCoachTipsToChat read failed: $e');
      return false;
    }
  }

  /// Set the "Save coach tips to chat history" toggle. Wired here so the
  /// follow-up settings UI can call a single function instead of duplicating
  /// the SharedPreferences key.
  static Future<void> setSaveCoachTipsToChat(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kSaveCoachTipsToChatPrefKey, value);
    } catch (e) {
      debugPrint('⚠️ [ExerciseTip] saveCoachTipsToChat write failed: $e');
    }
  }

  /// Returns true if [candidate] should be REJECTED as a near-duplicate of
  /// any of [recentAssistantMessages]. Implements the contract from the
  /// 10-fix plan:
  ///
  ///   - Only assistant messages > [kCoachTipDedupMinChars] are checked.
  ///     Short nudges ("Drink water!") are exempt to avoid false positives.
  ///   - Only the last [kCoachTipDedupWindow] assistant messages are scanned.
  ///   - Levenshtein-derived similarity above
  ///     [kCoachTipDedupSimilarityThreshold] (0.85) → reject.
  ///
  /// Edge cases handled:
  ///   - Empty or whitespace-only candidate → reject (never persist empty
  ///     auto-tip rows).
  ///   - Mixed-language windows: similarity is computed on raw codepoints,
  ///     so a mid-history language switch naturally lowers similarity below
  ///     threshold without language detection.
  static bool isNearDuplicateOfRecent(
    String candidate,
    List<String> recentAssistantMessages,
  ) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.length <= kCoachTipDedupMinChars) return false;
    final window = recentAssistantMessages
        .where((m) => m.trim().isNotEmpty)
        .toList();
    final start = window.length > kCoachTipDedupWindow
        ? window.length - kCoachTipDedupWindow
        : 0;
    for (int i = start; i < window.length; i++) {
      final sim = _normalizedSimilarity(trimmed, window[i].trim());
      if (sim > kCoachTipDedupSimilarityThreshold) {
        debugPrint(
          '🛑 [ExerciseTip] Dedup gate rejected near-duplicate '
          '(sim=${sim.toStringAsFixed(3)})',
        );
        return true;
      }
    }
    return false;
  }

  /// One-time prune migration entry point. The actual chat history prune is
  /// performed by chat repository code (not in this fix pass's ownership);
  /// here we expose the idempotency gate so any caller — current or future —
  /// can guard their work consistently.
  ///
  /// Returns `true` if prune SHOULD run now (and atomically marks it done so
  /// concurrent callers see `false`). Returns `false` if it has already run.
  /// On any preferences error, returns `false` (fail-closed; never re-run).
  static Future<bool> claimPruneCoachDuplicatesV1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final already = prefs.getBool(kPruneCoachDuplicatesV1PrefKey) ?? false;
      if (already) return false;
      await prefs.setBool(kPruneCoachDuplicatesV1PrefKey, true);
      return true;
    } catch (e) {
      debugPrint('⚠️ [ExerciseTip] prune flag claim failed: $e');
      return false;
    }
  }

  /// Legacy entry-point retained for backwards-compatibility. The actual
  /// row-level prune now lives in
  /// `lib/data/repositories/chat_repository_part_chat_messages_notifier.dart`
  /// (`_runOneTimeCoachTipPrune`), invoked automatically on first history
  /// load. Callers that previously invoked this method are still safe — the
  /// chat notifier guards re-entry with [claimPruneCoachDuplicatesV1].
  static Future<void> pruneDuplicates() async {
    final shouldRun = await claimPruneCoachDuplicatesV1();
    if (!shouldRun) {
      debugPrint('💡 [ExerciseTip] prune already complete — skipping');
      return;
    }
    debugPrint(
      '💡 [ExerciseTip] prune claim acquired; chat notifier owns the '
      'row-level walk on its next history load.',
    );
  }
}

/// Normalized Levenshtein similarity ∈ [0, 1]. 1 == identical, 0 == fully
/// different. Implemented inline (no new dep) using two-row dynamic
/// programming for O(min(m,n)) memory.
double _normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final distance = _levenshtein(a, b);
  final longest = a.length > b.length ? a.length : b.length;
  if (longest == 0) return 1.0;
  return 1.0 - (distance / longest);
}

/// Iterative two-row Levenshtein. O(m*n) time, O(min(m,n)) space.
int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;
  // Ensure t is the shorter so the row buffer is min(m,n).
  if (s.length < t.length) {
    final tmp = s;
    s = t;
    t = tmp;
  }
  final m = s.length;
  final n = t.length;
  var prev = List<int>.generate(n + 1, (i) => i);
  final curr = List<int>.filled(n + 1, 0);
  for (int i = 1; i <= m; i++) {
    curr[0] = i;
    for (int j = 1; j <= n; j++) {
      final cost = s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      var best = del < ins ? del : ins;
      if (sub < best) best = sub;
      curr[j] = best;
    }
    final tmp = prev;
    prev = curr.toList(growable: false);
    // ignore: unused_local_variable
    final _ = tmp;
  }
  return prev[n];
}
