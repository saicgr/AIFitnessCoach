import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_preferences.dart';
import '../models/meal_macro_targets.dart';
import '../repositories/nutrition_preferences_repository.dart';
import '../repositories/auth_repository.dart';

/// Tracks the user_id this static cache belongs to, so we can flush it on a
/// real account switch and avoid the new user inheriting the prior user's
/// nutrition preferences.
String? _nutritionPrefsCacheOwnerUserId;

/// SharedPreferences key prefix for the one-time targets-recalc migration.
/// We bumped the rate→deficit table on this date (the textbook
/// `kg/wk × 7700 / 7` rule); existing users with stale `target_calories`
/// (e.g. 2884 for a 100kg → 75kg @ 1.0 kg/wk profile) need a one-shot
/// re-derive on next app open. Stored per-user so an account switch
/// triggers a fresh check.
const String _targetsRecalcV2DonePrefPrefix = 'nutrition_targets_recalc_v2_done_';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
NutritionPreferencesState? _nutritionPrefsInMemoryCache;

// ===========================================================================
// _NutritionPrefsDiskCache — stale-while-revalidate disk cache (A2)
// ===========================================================================

/// Persistent (cross-launch) cache for the user's `NutritionPreferences`.
///
/// Mirrors `_NutritionDiskCache`: a JSON-encoded `NutritionPreferences` in a
/// versioned, user-scoped envelope. Preferences are NOT daily, so the cache
/// is keyed only by user_id — no date stamp. Powers cold-start
/// stale-while-revalidate: the nutrition prefs (target calories/macros that
/// the Home macro ring reads) render instantly while `initialize` revalidates
/// from the backend.
class _NutritionPrefsDiskCache {
  static const _prefix = 'nutrition_prefs_v1::';
  // v2: the envelope now ALSO persists the last-known `dynamic_targets` so a
  // cold start can seed the real adjusted calorie target (e.g. 1700) instantly
  // instead of the base `preferences.target_calories` (e.g. 2000) and then
  // visibly jumping once the network confirms. v1 envelopes are dropped on read
  // (one harmless refetch on the update boundary).
  static const _schemaVersion = 2;

  static String _key(String userId) => '$_prefix$userId';

  /// Read the persisted preferences + last-known dynamic targets, or null on
  /// miss / schema mismatch / malformed JSON. Never throws — a stale render is
  /// corrected by the network revalidation.
  static Future<({NutritionPreferences preferences, DynamicNutritionTargets? dynamicTargets})?>
      read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      if (envelope['v'] != _schemaVersion) return null; // drop on schema bump
      final body = envelope['preferences'];
      if (body is! Map<String, dynamic>) return null;
      final preferences = NutritionPreferences.fromJson(body);
      DynamicNutritionTargets? dynamicTargets;
      final dyn = envelope['dynamic_targets'];
      if (dyn is Map<String, dynamic>) {
        try {
          dynamicTargets = DynamicNutritionTargets.fromJson(dyn);
        } catch (_) {/* tolerate a malformed dynamic block; prefs still usable */}
      }
      return (preferences: preferences, dynamicTargets: dynamicTargets);
    } catch (e) {
      debugPrint('🥗 [NutritionPrefsDiskCache] read failed: $e');
      return null;
    }
  }

  /// Write-through the preferences + (optionally) the current dynamic targets.
  /// Best-effort.
  static Future<void> write(
    String userId,
    NutritionPreferences value, [
    DynamicNutritionTargets? dynamicTargets,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'v': _schemaVersion,
          'cached_at': DateTime.now().toIso8601String(),
          'preferences': value.toJson(),
          if (dynamicTargets != null) 'dynamic_targets': dynamicTargets.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('🥗 [NutritionPrefsDiskCache] write failed: $e');
    }
  }

  /// Drop the cache — provided for logout / account-switch cleanup parity
  /// with `_NutritionDiskCache.clear`.
  // ignore: unused_element
  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {/* best-effort */}
  }
}

// ============================================
// Nutrition Preferences State
// ============================================

/// Complete nutrition preferences state
class NutritionPreferencesState {
  final NutritionPreferences? preferences;
  final NutritionStreak? streak;
  final List<WeightLog> weightHistory;
  final WeightTrend? weightTrend;
  final DynamicNutritionTargets? dynamicTargets;
  final AdaptiveCalculation? adaptiveCalculation;
  final bool isLoading;
  final String? error;
  final bool onboardingCompleted;

  /// Per-meal-targets preference state (Phase 1c). These two live OUTSIDE the
  /// `@JsonSerializable` `NutritionPreferences` model (no build_runner), so we
  /// track them here. `perMealMacroTargets` is the raw
  /// `{mode, split, overrides}` object the edit sheet reads/writes.
  final bool perMealTargetsEnabled;
  final Map<String, dynamic>? perMealMacroTargets;

  /// Set when the one-time targets-recalc migration ran AND actually changed
  /// the stored daily calorie target (delta != 0). NutritionScreen reads this
  /// on mount, shows a SnackBar like "Updated your daily target: 1580 cal/day
  /// (was 2884) — Review", then clears it via `consumePendingMigrationDelta`.
  /// Null when no migration was needed or the recalc happened to land on the
  /// same number.
  final ({int oldCalories, int newCalories})? pendingMigrationDelta;

  const NutritionPreferencesState({
    this.preferences,
    this.streak,
    this.weightHistory = const [],
    this.weightTrend,
    this.dynamicTargets,
    this.adaptiveCalculation,
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
    this.pendingMigrationDelta,
    this.perMealTargetsEnabled = false,
    this.perMealMacroTargets,
  });

  NutritionPreferencesState copyWith({
    NutritionPreferences? preferences,
    NutritionStreak? streak,
    List<WeightLog>? weightHistory,
    WeightTrend? weightTrend,
    DynamicNutritionTargets? dynamicTargets,
    AdaptiveCalculation? adaptiveCalculation,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
    bool clearError = false,
    ({int oldCalories, int newCalories})? pendingMigrationDelta,
    bool clearPendingMigrationDelta = false,
    bool? perMealTargetsEnabled,
    Map<String, dynamic>? perMealMacroTargets,
    bool clearPerMealMacroTargets = false,
  }) {
    return NutritionPreferencesState(
      preferences: preferences ?? this.preferences,
      streak: streak ?? this.streak,
      weightHistory: weightHistory ?? this.weightHistory,
      weightTrend: weightTrend ?? this.weightTrend,
      dynamicTargets: dynamicTargets ?? this.dynamicTargets,
      adaptiveCalculation: adaptiveCalculation ?? this.adaptiveCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      pendingMigrationDelta: clearPendingMigrationDelta
          ? null
          : (pendingMigrationDelta ?? this.pendingMigrationDelta),
      perMealTargetsEnabled:
          perMealTargetsEnabled ?? this.perMealTargetsEnabled,
      perMealMacroTargets: clearPerMealMacroTargets
          ? null
          : (perMealMacroTargets ?? this.perMealMacroTargets),
    );
  }

  /// True when the user has actually configured nutrition targets — i.e.
  /// either dynamic targets are present or stored preferences carry a
  /// non-null target. UI should branch on this and show a "Set a target"
  /// CTA instead of presenting the placeholder 2000-cal fallback as if it
  /// were a real plan.
  bool get hasConfiguredTargets =>
      dynamicTargets?.targetCalories != null ||
      preferences?.targetCalories != null;

  /// Get current calorie target (dynamic if available, otherwise base).
  /// Returns a SAFE non-null value for arithmetic; callers that need to
  /// distinguish "real plan" vs. "no plan set" must check
  /// [hasConfiguredTargets] FIRST and render a "Set a target" CTA when
  /// false. Never present the fallback as a real plan.
  int get currentCalorieTarget =>
      dynamicTargets?.targetCalories ?? preferences?.targetCalories ?? 2000;

  /// Get current protein target. See note on [currentCalorieTarget].
  int get currentProteinTarget =>
      dynamicTargets?.targetProteinG ?? preferences?.targetProteinG ?? 150;

  /// Get current carbs target. See note on [currentCalorieTarget].
  int get currentCarbsTarget =>
      dynamicTargets?.targetCarbsG ?? preferences?.targetCarbsG ?? 200;

  /// Get current fat target. See note on [currentCalorieTarget].
  int get currentFatTarget =>
      dynamicTargets?.targetFatG ?? preferences?.targetFatG ?? 65;

  /// Check if today is a training day
  bool get isTrainingDay => dynamicTargets?.isTrainingDay ?? false;

  /// Check if today is a fasting day (5:2, ADF)
  bool get isFastingDay => dynamicTargets?.isFastingDay ?? false;

  /// Get latest weight
  double? get latestWeight =>
      weightHistory.isNotEmpty ? weightHistory.first.weightKg : null;

  /// Per-meal targets for TODAY (from the dynamic-targets payload), or null
  /// when the feature is disabled / not configured. Keyed by meal type
  /// (`breakfast`/`lunch`/`dinner`/`snacks`). Past dates are served by the
  /// date-keyed [perMealTargetsForDateProvider] family instead.
  Map<String, MealMacroTargets>? get perMealTargetsToday =>
      perMealTargetsEnabled ? dynamicTargets?.perMealTargets : null;
}

// ============================================
// Nutrition Preferences Notifier
// ============================================

/// Nutrition preferences state notifier
class NutritionPreferencesNotifier extends StateNotifier<NutritionPreferencesState> {
  final NutritionPreferencesRepository _repository;

  // De-dupe guards. Without these, every widget that mounts and sees
  // `prefs == null && !isLoading` re-fires initialize(), and for users with
  // no nutrition prefs row that condition stays true after each call —
  // hammering the 4-endpoint init at frame rate (HTTP 429 storm).
  Future<void>? _inFlightInit;
  bool _initAttempted = false;
  // True when the LAST preferences fetch threw (timeout / 5xx) rather than
  // cleanly returning null (404 = genuinely-new user). A transient error must
  // NOT stick the user at the hardcoded 2000/150/200/65 default all session —
  // so we allow the next initialize() to retry. See _runInitialize.
  bool _prefsLoadErrored = false;

  NutritionPreferencesNotifier(this._repository)
      : super(_nutritionPrefsInMemoryCache ?? const NutritionPreferencesState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _nutritionPrefsInMemoryCache = null;
    debugPrint('🧹 [NutritionPrefsProvider] In-memory cache cleared');
  }

  /// Seed the calorie/macro TARGETS from the `/home/bootstrap` payload so the
  /// Home + Nutrition calorie ring renders the real target on first paint —
  /// no "Set a calorie target" flash on a fresh install where the prefs disk
  /// cache is still empty and the slowest link is the separate
  /// `/nutrition/dynamic-targets` round-trip.
  ///
  /// No-op once any preferences already exist (disk-cache seed or a network
  /// load got there first), so it never clobbers richer data or the
  /// cycle/training-adjusted dynamic targets. The background [initialize] still
  /// runs and refines the ring to the dynamic-adjusted figure silently.
  void seedFromBootstrap({
    required String userId,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
  }) {
    if (state.preferences != null) return;
    if (targetCalories == null &&
        targetProteinG == null &&
        targetCarbsG == null &&
        targetFatG == null) {
      return; // nothing to seed
    }
    debugPrint('🥗 [NutritionPrefsProvider] Seeded targets from bootstrap '
        '($targetCalories kcal)');
    state = state.copyWith(
      preferences: NutritionPreferences(
        userId: userId,
        targetCalories: targetCalories,
        targetProteinG: targetProteinG,
        targetCarbsG: targetCarbsG,
        targetFatG: targetFatG,
      ),
    );
  }

  /// Initialize nutrition preferences for a user.
  /// Set [forceRefresh] to bypass the in-memory cache and re-fetch from backend.
  Future<void> initialize(String userId, {bool forceRefresh = false}) async {
    // Coalesce concurrent callers onto the same future.
    if (_inFlightInit != null) return _inFlightInit;

    if (!forceRefresh) {
      // Skip re-initialization if already loaded and onboarding is complete
      // The in-memory flag is preserved once set
      if (state.preferences != null && state.onboardingCompleted) {
        debugPrint('🥗 [NutritionPrefsProvider] Already initialized and onboarding complete, skipping');
        return;
      }

      // Also skip if we already have preferences with backend flag set
      // This handles the case where we navigated away and back
      if (state.preferences?.nutritionOnboardingCompleted == true) {
        debugPrint('🥗 [NutritionPrefsProvider] Backend flag says complete, skipping reinit');
        if (!state.onboardingCompleted) {
          state = state.copyWith(onboardingCompleted: true);
        }
        return;
      }

      // Already attempted at least once this session and prefs are still
      // null (user has no row). Don't re-fetch unless forceRefresh — caller
      // must opt in to a retry.
      // Skip only if a PRIOR attempt cleanly completed (prefs genuinely null =
      // new user). If the last attempt ERRORED (timeout/5xx), allow a retry so
      // a transient failure never sticks the card at the 2000 default.
      if (_initAttempted && !_prefsLoadErrored) {
        debugPrint('🥗 [NutritionPrefsProvider] Init already attempted, skipping (use forceRefresh to retry)');
        return;
      }
    }

    final future = _runInitialize(userId);
    _inFlightInit = future;
    try {
      await future;
    } finally {
      _inFlightInit = null;
      _initAttempted = true;
    }
  }

  Future<void> _runInitialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Stale-while-revalidate (A2): seed preferences from the disk cache so the
    // Home macro ring / target calories render instantly on a cold start,
    // before the network round-trip below. Only when in-memory state is empty.
    if (state.preferences == null) {
      final cached = await _NutritionPrefsDiskCache.read(userId);
      if (cached != null && state.preferences == null) {
        debugPrint('🥗 [NutritionPrefsProvider] Seeded preferences (+dynamic) from disk cache');
        state = state.copyWith(
          preferences: cached.preferences,
          // Seed the last-known dynamic targets too, so the calorie ring shows
          // the real adjusted value (e.g. 1700) on a cold start instead of the
          // base `target_calories` (e.g. 2000) until the network confirms. Only
          // when we don't already hold a fresher one in memory.
          dynamicTargets: state.dynamicTargets ?? cached.dynamicTargets,
          // Honour the cached backend flag so onboarding gating is correct
          // even before the network confirms.
          onboardingCompleted: state.onboardingCompleted ||
              cached.preferences.nutritionOnboardingCompleted,
        );
      }
    }

    _prefsLoadErrored = false;
    try {
      debugPrint('🥗 [NutritionPrefsProvider] Initializing for $userId');

      // CRITICAL PATH vs SECONDARY PATH.
      //
      // The Home / Nutrition calorie ring + macro targets depend ONLY on
      // `preferences` + `dynamicTargets`. The streak, weight-log history and
      // weight-trend are unrelated concerns. Previously all four were bundled
      // into one `Future.wait` PLUS a sequential `getWeightTrend`, and the
      // result was surfaced to the UI in a SINGLE `state.copyWith` only after
      // ALL FIVE network calls resolved. So a slow/hanging streak, weight-log
      // or weight-trend call (up to the 25-30s connect/receive timeout, ×2
      // retries on connect ≈ a minute+) held the already-arrived
      // `dynamicTargets` hostage — the ring sat at the disk-seeded base 2000
      // for "a few minutes", then jumped to the real 1700. (feedback_instant_data)
      //
      // Fix: kick off ALL fetches concurrently, but emit the targets to the UI
      // the INSTANT `preferences` + `dynamicTargets` resolve, decoupled from
      // streak/weight which land afterwards on their own.
      final prefsFuture = _repository.getPreferences(userId).catchError((e) {
        _prefsLoadErrored = true;
        debugPrint('⚠️ [NutritionPrefsProvider] getPreferences failed, keeping cached targets + will retry: $e');
        return state.preferences;
      });
      // NOTE: do NOT .catchError → const DynamicNutritionTargets() here. That
      // default has targetCalories=2000, and since currentCalorieTarget reads
      // dynamicTargets FIRST, a failed dynamic fetch would shadow the real
      // preferences.target_calories (e.g. 1500) and render "2000 of 2000".
      // Awaited in a try/catch below so a failure yields null (→ fall through
      // to the real base target), never a fake 2000.
      final dynamicFuture = _repository
          .getDynamicTargets(userId: userId, date: DateTime.now());
      // Per-meal-targets preference fields (live outside the codegen model).
      // Never fatal — a failure leaves the feature disabled rather than
      // blocking the calorie ring.
      final perMealPrefsFuture = _repository
          .getPerMealTargetsPrefs(userId)
          .catchError((_) => const PerMealTargetsPrefs());
      final streakFuture = _repository.getStreak(userId).catchError((_) => NutritionStreak(
            userId: userId,
            currentStreakDays: 0,
            longestStreakEver: 0,
            freezesAvailable: 2,
            freezesUsedThisWeek: 0,
            totalDaysLogged: 0,
            weeklyGoalEnabled: false,
            weeklyGoalDays: 5,
            daysLoggedThisWeek: 0,
          ));
      final weightFuture =
          _repository.getWeightLogs(userId: userId, limit: 30).catchError((_) => <WeightLog>[]);

      // ── Critical path: surface the calorie/macro targets the moment they
      //    land. Does NOT await streak/weight/trend. ──
      final preferences = await prefsFuture;
      DynamicNutritionTargets? dynamicTargets;
      try {
        dynamicTargets = await dynamicFuture;
      } catch (e) {
        // Dynamic fetch failed — keep any prior REAL value, else null. Null
        // makes currentCalorieTarget fall through to preferences.targetCalories
        // (the real base) instead of the 2000 default.
        debugPrint(
            '⚠️ [NutritionPrefsProvider] getDynamicTargets failed, using base target: $e');
        dynamicTargets = state.dynamicTargets;
      }
      final wasOnboardingCompleted = state.onboardingCompleted;
      final backendOnboardingCompleted = preferences?.nutritionOnboardingCompleted ?? false;
      final perMealPrefs = await perMealPrefsFuture;
      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
        isLoading: false,
        onboardingCompleted: wasOnboardingCompleted || backendOnboardingCompleted,
        perMealTargetsEnabled: perMealPrefs.enabled,
        perMealMacroTargets: perMealPrefs.macroTargets,
        clearPerMealMacroTargets: perMealPrefs.macroTargets == null,
      );
      _nutritionPrefsInMemoryCache = state;
      // Write through to disk for the next cold start (A2) — now including the
      // dynamic targets so the ring opens on the real adjusted value.
      if (preferences != null) {
        unawaited(_NutritionPrefsDiskCache.write(userId, preferences, dynamicTargets));
      }
      debugPrint(
          '✅ [NutritionPrefsProvider] Targets ready: dynCal=${dynamicTargets?.targetCalories}, baseCal=${preferences?.targetCalories}, onboarded=${state.onboardingCompleted}');

      // ── Secondary path: streak + weight history (already in flight). A slow
      //    call here can no longer stall the calorie target. ──
      final streak = await streakFuture;
      final weightHistory = await weightFuture;
      WeightTrend? weightTrend;
      if (weightHistory.length >= 2) {
        try {
          weightTrend = await _repository.getWeightTrend(userId: userId);
        } catch (e) {
          debugPrint('⚠️ [NutritionPrefsProvider] Could not get weight trend: $e');
        }
      }
      state = state.copyWith(
        streak: streak,
        weightHistory: weightHistory,
        weightTrend: weightTrend,
      );
      _nutritionPrefsInMemoryCache = state;

      debugPrint(
          '✅ [NutritionPrefsProvider] Initialized: onboarded=${state.onboardingCompleted} (backend=$backendOnboardingCompleted, was=$wasOnboardingCompleted), weights=${weightHistory.length}');

      // One-time targets-recalc migration. The rate→deficit table changed
      // (slow/moderate/fast/aggressive now map to 275/550/825/1100 cal/d
      // instead of 250/500/750 with no "fast" entry). Existing users who
      // completed onboarding before this fix have stale `target_calories`.
      // Re-derive once, silently. Surfaces a SnackBar via
      // `pendingMigrationDelta` when the new target differs.
      await _maybeRunTargetsRecalcV2(userId);
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// One-shot recalc for users whose `target_calories` was computed under the
  /// old rate→deficit table. Eligible: lose_fat or build_muscle goals with a
  /// non-null rate_of_change. Idempotent — gated by a per-user
  /// SharedPreferences flag.
  Future<void> _maybeRunTargetsRecalcV2(String userId) async {
    try {
      final prefs = state.preferences;
      if (prefs == null) return;
      final goal = prefs.primaryGoalEnum;
      final rate = prefs.rateOfChange;
      // Only weight-changing goals depend on the rate-derived deficit.
      if (goal != NutritionGoal.loseFat && goal != NutritionGoal.buildMuscle) {
        return;
      }
      if (rate == null || rate.isEmpty) return;
      // Skip when TDEE isn't available — recalc would no-op or fail anyway.
      if ((prefs.calculatedTdee ?? 0) <= 0) return;

      final spref = await SharedPreferences.getInstance();
      final flagKey = '$_targetsRecalcV2DonePrefPrefix$userId';
      if (spref.getBool(flagKey) == true) return;

      final oldCal = prefs.targetCalories ?? 0;
      debugPrint('🔁 [NutritionPrefsProvider] Running v2 targets recalc (old=$oldCal cal)');

      final updated = await _repository.recalculateTargets(userId);
      final newCal = updated.targetCalories ?? oldCal;

      // Always set the flag — even if the new number happens to match the
      // old, we don't want to keep re-running the recalc on every cold start.
      await spref.setBool(flagKey, true);

      _nutritionPrefsInMemoryCache = state.copyWith(
        preferences: updated,
        // Only show the banner when the number actually moved enough to
        // matter. < 25 cal isn't worth interrupting the user over.
        pendingMigrationDelta: (oldCal > 0 && (newCal - oldCal).abs() >= 25)
            ? (oldCalories: oldCal, newCalories: newCal)
            : null,
      );
      state = _nutritionPrefsInMemoryCache!;
      // Persist the recalculated preferences so the next cold start is fresh.
      unawaited(_NutritionPrefsDiskCache.write(userId, updated));

      debugPrint('✅ [NutritionPrefsProvider] v2 recalc done: $oldCal → $newCal cal');
    } catch (e) {
      // Don't block app start on this — surface in logs only. The user can
      // still tap "Recalculate from profile" in EditTargetsSheet manually.
      debugPrint('⚠️ [NutritionPrefsProvider] v2 recalc failed (will retry next launch): $e');
    }
  }

  /// Called by NutritionScreen after it has shown the one-time migration
  /// SnackBar. Clears the pending delta so it doesn't re-fire on rebuild.
  void consumePendingMigrationDelta() {
    if (state.pendingMigrationDelta == null) return;
    state = state.copyWith(clearPendingMigrationDelta: true);
    _nutritionPrefsInMemoryCache = state;
  }

  /// Complete nutrition onboarding (supports multi-select goals)
  Future<void> completeOnboarding({
    required String userId,
    required List<NutritionGoal> goals, // Multi-select goals
    RateOfChange? rateOfChange,
    required DietType dietType,
    List<FoodAllergen> allergies = const [],
    List<DietaryRestriction> restrictions = const [],
    required MealPattern mealPattern,
    int? fastingStartHour,
    int? fastingEndHour,
    CookingSkill cookingSkill = CookingSkill.intermediate,
    int cookingTimeMinutes = 30,
    BudgetLevel budgetLevel = BudgetLevel.moderate,
    int? customCarbPercent,
    int? customProteinPercent,
    int? customFatPercent,
    // Pre-calculated values from frontend to ensure consistency
    int? calculatedBmr,
    int? calculatedTdee,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🎓 [NutritionPrefsProvider] Completing onboarding with ${goals.length} goals');
      if (targetCalories != null) {
        debugPrint('🎓 [NutritionPrefsProvider] Using frontend-calculated values: $targetCalories cal');
      }
      final preferences = await _repository.completeOnboarding(
        userId: userId,
        goals: goals,
        rateOfChange: rateOfChange,
        dietType: dietType,
        allergies: allergies,
        restrictions: restrictions,
        mealPattern: mealPattern,
        fastingStartHour: fastingStartHour,
        fastingEndHour: fastingEndHour,
        cookingSkill: cookingSkill,
        cookingTimeMinutes: cookingTimeMinutes,
        budgetLevel: budgetLevel,
        customCarbPercent: customCarbPercent,
        customProteinPercent: customProteinPercent,
        customFatPercent: customFatPercent,
        calculatedBmr: calculatedBmr,
        calculatedTdee: calculatedTdee,
        targetCalories: targetCalories,
        targetProteinG: targetProteinG,
        targetCarbsG: targetCarbsG,
        targetFatG: targetFatG,
      );

      // Also get dynamic targets (pass local date to avoid timezone mismatch with server UTC)
      final dynamicTargets =
          await _repository.getDynamicTargets(userId: userId, date: DateTime.now());

      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
        onboardingCompleted: true,
        isLoading: false,
      );
      _nutritionPrefsInMemoryCache = state;
      unawaited(_NutritionPrefsDiskCache.write(userId, preferences));
      debugPrint('✅ [NutritionPrefsProvider] Onboarding completed (saved to backend)');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Onboarding error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Skip nutrition onboarding permanently
  /// This saves the skip to the database so the user won't see onboarding again
  Future<void> skipOnboarding({required String userId}) async {
    try {
      debugPrint('⏭️ [NutritionPrefsProvider] Skipping onboarding for user $userId');
      await _repository.skipOnboarding(userId: userId);
      state = state.copyWith(onboardingCompleted: true);
      debugPrint('✅ [NutritionPrefsProvider] Onboarding skipped (saved to backend)');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Skip onboarding error: $e');
      // Still mark as completed in memory so user isn't bothered again this session
      state = state.copyWith(onboardingCompleted: true);
    }
  }

  /// Save nutrition preferences
  Future<void> savePreferences({
    required String userId,
    required NutritionPreferences preferences,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('💾 [NutritionPrefsProvider] Saving preferences');
      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: preferences,
      );
      state = state.copyWith(preferences: saved, isLoading: false);
      _nutritionPrefsInMemoryCache = state;
      unawaited(_NutritionPrefsDiskCache.write(userId, saved));
      debugPrint('✅ [NutritionPrefsProvider] Preferences saved');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Save preferences error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Log a weight entry
  Future<void> logWeight({
    required String userId,
    required double weightKg,
    DateTime? loggedAt,
    String? notes,
  }) async {
    try {
      debugPrint('⚖️ [NutritionPrefsProvider] Logging weight: $weightKg kg');
      final log = await _repository.logWeight(
        userId: userId,
        weightKg: weightKg,
        loggedAt: loggedAt,
        notes: notes,
      );

      // Update weight history
      final updatedHistory = [log, ...state.weightHistory];
      state = state.copyWith(weightHistory: updatedHistory);

      // Refresh weight trend if we have enough data
      if (updatedHistory.length >= 2) {
        try {
          final trend = await _repository.getWeightTrend(userId: userId);
          state = state.copyWith(weightTrend: trend);
        } catch (e) {
          debugPrint('⚠️ [NutritionPrefsProvider] Could not update trend: $e');
        }
      }

      debugPrint('✅ [NutritionPrefsProvider] Weight logged');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Log weight error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a weight log
  Future<void> deleteWeightLog({
    required String userId,
    required String logId,
  }) async {
    try {
      debugPrint('🗑️ [NutritionPrefsProvider] Deleting weight log $logId');
      await _repository.deleteWeightLog(userId: userId, logId: logId);

      // Remove from local state
      final updatedHistory =
          state.weightHistory.where((w) => w.id != logId).toList();
      state = state.copyWith(weightHistory: updatedHistory);

      debugPrint('✅ [NutritionPrefsProvider] Weight log deleted');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Delete weight error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Force-reload preferences from backend, bypassing the skip-if-already-loaded logic.
  /// Use this after calculate-nutrition-targets so the Profile card reflects the new goal/macros.
  Future<void> forceRefreshPreferences(String userId) async {
    try {
      debugPrint('🔄 [NutritionPrefsProvider] Force-refreshing preferences for $userId');
      // Fire both concurrently, but NEVER fall back to a default
      // DynamicNutritionTargets() (targetCalories defaults to 2000, which would
      // shadow the real base target). A failed dynamic fetch yields null so the
      // calorie getters fall through to the real preferences value.
      final prefsFuture = _repository.getPreferences(userId);
      final dynFuture =
          _repository.getDynamicTargets(userId: userId, date: DateTime.now());
      final preferences = await prefsFuture;
      DynamicNutritionTargets? dynamicTargets;
      try {
        dynamicTargets = await dynFuture;
      } catch (e) {
        debugPrint(
            '⚠️ [NutritionPrefsProvider] force-refresh dynamic failed, keeping base: $e');
        dynamicTargets = state.dynamicTargets;
      }
      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets,
      );
      _nutritionPrefsInMemoryCache = state;
      if (preferences != null) {
        unawaited(_NutritionPrefsDiskCache.write(userId, preferences, dynamicTargets));
      }
      debugPrint('✅ [NutritionPrefsProvider] Force-refresh done: goal=${preferences?.nutritionGoals}, cal=${preferences?.targetCalories}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Force-refresh error: $e');
    }
  }

  /// Refresh dynamic targets
  Future<void> refreshDynamicTargets(String userId) async {
    try {
      final targets = await _repository.getDynamicTargets(userId: userId, date: DateTime.now());
      state = state.copyWith(dynamicTargets: targets);
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Refresh targets error: $e');
    }
  }

  /// Use a streak freeze
  Future<void> useStreakFreeze(String userId) async {
    try {
      debugPrint('🧊 [NutritionPrefsProvider] Using streak freeze');
      final streak = await _repository.useStreakFreeze(userId);
      state = state.copyWith(streak: streak);
      debugPrint('✅ [NutritionPrefsProvider] Streak freeze used');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Streak freeze error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Recalculate nutrition targets
  Future<void> recalculateTargets(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 [NutritionPrefsProvider] Recalculating targets');
      final preferences = await _repository.recalculateTargets(userId);
      // The recalc PUT has already persisted the new baseline server-side. The
      // dynamic-targets GET is a SECONDARY enrichment — if it fails we must NOT
      // discard the freshly-recalculated `preferences` (that was the 2000-vs-
      // 1500 bug: a throwing getDynamicTargets sent us to catch{} and the new
      // baseline never reached state, so Home/Profile kept the stale fallback).
      DynamicNutritionTargets? dynamicTargets;
      try {
        dynamicTargets =
            await _repository.getDynamicTargets(userId: userId, date: DateTime.now());
      } catch (e) {
        debugPrint(
            '⚠️ [NutritionPrefsProvider] Dynamic refresh failed after recalc: $e (keeping baseline)');
      }
      state = state.copyWith(
        preferences: preferences,
        dynamicTargets: dynamicTargets ?? state.dynamicTargets,
        isLoading: false,
      );
      _nutritionPrefsInMemoryCache = state;
      unawaited(_NutritionPrefsDiskCache.write(userId, preferences));
      debugPrint('✅ [NutritionPrefsProvider] Targets recalculated');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Recalculate error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Trigger adaptive calculation
  Future<void> calculateAdaptive(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🧮 [NutritionPrefsProvider] Calculating adaptive');
      final calculation = await _repository.calculateAdaptive(userId);
      state = state.copyWith(
        adaptiveCalculation: calculation,
        isLoading: false,
      );
      debugPrint('✅ [NutritionPrefsProvider] Adaptive calculated: TDEE=${calculation.calculatedTdee}');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Adaptive calculation error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Respond to weekly nutrition recommendation
  Future<void> respondToRecommendation({
    required String userId,
    required String recommendationId,
    required bool accepted,
  }) async {
    try {
      debugPrint('📝 [NutritionPrefsProvider] Responding to recommendation: accepted=$accepted');
      await _repository.respondToRecommendation(
        userId: userId,
        recommendationId: recommendationId,
        accepted: accepted,
      );

      // Refresh preferences if accepted
      if (accepted) {
        await initialize(userId);
      }

      debugPrint('✅ [NutritionPrefsProvider] Response saved');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Response error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update nutrition targets (calories and macros)
  /// This allows users to manually edit their calorie/macro goals
  /// Save new daily targets with optimistic UI. The local state updates
  /// synchronously so the Edit sheet can close instantly and the Daily ring
  /// reflects the new baseline in the same frame. Persistence (PUT) + the
  /// dynamic-targets refresh (GET) run in the background; on failure the
  /// state rolls back to the previous values and the error surfaces via
  /// [state.error]. Previously this awaited both network calls before
  /// returning, blocking the UI for 1-6+ seconds on a slow backend.
  Future<void> updateTargets({
    required String userId,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
    int? customProteinPercent,
    int? customCarbPercent,
    int? customFatPercent,
    String? rateOfChange,
  }) async {
    if (state.preferences == null) {
      debugPrint('❌ [NutritionPrefsProvider] Cannot update targets: no preferences loaded');
      return;
    }

    final previousPreferences = state.preferences!;
    final previousDynamicTargets = state.dynamicTargets;

    // Build the optimistic preferences value.
    final updatedPreferences = previousPreferences.copyWith(
      targetCalories: targetCalories ?? previousPreferences.targetCalories,
      targetProteinG: targetProteinG ?? previousPreferences.targetProteinG,
      targetCarbsG: targetCarbsG ?? previousPreferences.targetCarbsG,
      targetFatG: targetFatG ?? previousPreferences.targetFatG,
      customProteinPercent:
          customProteinPercent ?? previousPreferences.customProteinPercent,
      customCarbPercent:
          customCarbPercent ?? previousPreferences.customCarbPercent,
      customFatPercent:
          customFatPercent ?? previousPreferences.customFatPercent,
      rateOfChange: rateOfChange ?? previousPreferences.rateOfChange,
    );

    // Apply the same calorie/macro delta to the cached dynamic targets so
    // the Daily ring keeps showing today's training/rest adjustment instead
    // of flickering back to the bare baseline while the GET refresh is in
    // flight. Falls back to null when there's no prior dynamic snapshot —
    // the UI will read the baseline directly via currentCalorieTarget.
    DynamicNutritionTargets? optimisticDynamic;
    if (previousDynamicTargets != null) {
      final calDelta =
          (targetCalories ?? previousPreferences.targetCalories ?? 0) -
              (previousPreferences.targetCalories ?? 0);
      final proteinDelta =
          (targetProteinG ?? previousPreferences.targetProteinG ?? 0) -
              (previousPreferences.targetProteinG ?? 0);
      final carbsDelta =
          (targetCarbsG ?? previousPreferences.targetCarbsG ?? 0) -
              (previousPreferences.targetCarbsG ?? 0);
      final fatDelta = (targetFatG ?? previousPreferences.targetFatG ?? 0) -
          (previousPreferences.targetFatG ?? 0);
      optimisticDynamic = DynamicNutritionTargets(
        // Preserve the dynamic adjustment when one existed; leave null (fall
        // through to the updated base target) when the prior dynamic value was
        // absent — never fabricate a number.
        targetCalories: previousDynamicTargets.targetCalories == null
            ? null
            : previousDynamicTargets.targetCalories! + calDelta,
        targetProteinG: previousDynamicTargets.targetProteinG == null
            ? null
            : previousDynamicTargets.targetProteinG! + proteinDelta,
        targetCarbsG: previousDynamicTargets.targetCarbsG == null
            ? null
            : previousDynamicTargets.targetCarbsG! + carbsDelta,
        targetFatG: previousDynamicTargets.targetFatG == null
            ? null
            : previousDynamicTargets.targetFatG! + fatDelta,
        targetFiberG: previousDynamicTargets.targetFiberG,
        isTrainingDay: previousDynamicTargets.isTrainingDay,
        isFastingDay: previousDynamicTargets.isFastingDay,
        isRestDay: previousDynamicTargets.isRestDay,
        adjustmentReason: previousDynamicTargets.adjustmentReason,
        calorieAdjustment: previousDynamicTargets.calorieAdjustment,
      );
    }

    // Synchronous optimistic state update — Edit sheet sees this in the
    // same frame and can close immediately. No `isLoading: true` flash.
    state = state.copyWith(
      preferences: updatedPreferences,
      dynamicTargets: optimisticDynamic,
      isLoading: false,
      clearError: true,
    );
    _nutritionPrefsInMemoryCache = state;
    unawaited(_NutritionPrefsDiskCache.write(userId, updatedPreferences));

    debugPrint(
        '📝 [NutritionPrefsProvider] Optimistic update applied: cal=$targetCalories, p=$targetProteinG, c=$targetCarbsG, f=$targetFatG');

    // Background persistence + dynamic-targets refresh. The Edit sheet has
    // already closed by the time these complete; the UI re-renders on the
    // confirmed server values.
    unawaited(() async {
      try {
        final saved = await _repository.savePreferences(
          userId: userId,
          preferences: updatedPreferences,
        );
        // Pull the real dynamic targets (backend re-runs the full
        // training/rest/fasting calc against the just-saved baseline).
        DynamicNutritionTargets? confirmedDynamic;
        try {
          confirmedDynamic = await _repository.getDynamicTargets(
            userId: userId,
            date: DateTime.now(),
          );
        } catch (e) {
          debugPrint(
              '⚠️ [NutritionPrefsProvider] Dynamic refresh failed: $e (keeping optimistic)');
        }
        state = state.copyWith(
          preferences: saved,
          dynamicTargets: confirmedDynamic ?? state.dynamicTargets,
        );
        _nutritionPrefsInMemoryCache = state;
        unawaited(_NutritionPrefsDiskCache.write(userId, saved));
        debugPrint('✅ [NutritionPrefsProvider] Targets persisted to backend');
      } catch (e) {
        debugPrint('❌ [NutritionPrefsProvider] Persist failed, rolling back: $e');
        // Rollback to pre-edit values + surface the error so the UI can
        // toast.
        state = state.copyWith(
          preferences: previousPreferences,
          dynamicTargets: previousDynamicTargets,
          error: e.toString(),
        );
        _nutritionPrefsInMemoryCache = state;
        unawaited(_NutritionPrefsDiskCache.write(userId, previousPreferences));
      }
    }());
  }

  /// Update the per-meal-targets preference (Phase 1c). Optimistically flips
  /// the local flag + raw macro-targets object so the edit sheet + display
  /// react in the same frame, then PUTs the prefs in the background and
  /// refreshes the dynamic targets (so the freshly-derived `per_meal_targets`
  /// split lands). Rolls back on failure.
  ///
  /// `enabled` → `per_meal_targets_enabled`. `macroTargets` → the raw
  /// `{mode, split, overrides}` object (pass null to clear, e.g. on disable).
  Future<void> updatePerMealTargets({
    required String userId,
    required bool enabled,
    Map<String, dynamic>? macroTargets,
  }) async {
    final base = state.preferences;
    if (base == null) {
      debugPrint(
          '❌ [NutritionPrefsProvider] Cannot update per-meal targets: no preferences');
      return;
    }

    final prevEnabled = state.perMealTargetsEnabled;
    final prevMacroTargets = state.perMealMacroTargets;

    // Optimistic local update.
    state = state.copyWith(
      perMealTargetsEnabled: enabled,
      perMealMacroTargets: macroTargets,
      clearPerMealMacroTargets: macroTargets == null,
      clearError: true,
    );
    _nutritionPrefsInMemoryCache = state;
    debugPrint(
        '🍽️ [NutritionPrefsProvider] Optimistic per-meal targets: enabled=$enabled, mode=${macroTargets?['mode']}');

    unawaited(() async {
      try {
        await _repository.updatePerMealTargetsPrefs(
          userId: userId,
          basePreferences: base,
          enabled: enabled,
          macroTargets: macroTargets,
        );
        // Pull fresh dynamic targets so the backend-derived per_meal_targets
        // split (auto, or recomputed from overrides) reaches the UI.
        try {
          final dyn = await _repository.getDynamicTargets(
            userId: userId,
            date: DateTime.now(),
          );
          state = state.copyWith(dynamicTargets: dyn);
          _nutritionPrefsInMemoryCache = state;
        } catch (e) {
          debugPrint(
              '⚠️ [NutritionPrefsProvider] Dynamic refresh after per-meal update failed: $e');
        }
        debugPrint('✅ [NutritionPrefsProvider] Per-meal targets persisted');
      } catch (e) {
        debugPrint(
            '❌ [NutritionPrefsProvider] Per-meal targets persist failed, rolling back: $e');
        state = state.copyWith(
          perMealTargetsEnabled: prevEnabled,
          perMealMacroTargets: prevMacroTargets,
          clearPerMealMacroTargets: prevMacroTargets == null,
          error: e.toString(),
        );
        _nutritionPrefsInMemoryCache = state;
      }
    }());
  }

  /// Record that weekly check-in was completed
  Future<void> recordWeeklyCheckin({required String userId}) async {
    if (state.preferences == null) {
      debugPrint('❌ [NutritionPrefsProvider] Cannot record check-in: no preferences loaded');
      return;
    }

    try {
      debugPrint('📅 [NutritionPrefsProvider] Recording weekly check-in completion');
      final updatedPreferences = state.preferences!.copyWith(
        lastWeeklyCheckinAt: DateTime.now(),
        weeklyCheckinDismissCount: 0,
      );

      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: updatedPreferences,
      );
      state = state.copyWith(preferences: saved);
      _nutritionPrefsInMemoryCache = state;
      unawaited(_NutritionPrefsDiskCache.write(userId, saved));

      debugPrint('✅ [NutritionPrefsProvider] Weekly check-in recorded, dismiss counter reset');
    } catch (e) {
      debugPrint('❌ [NutritionPrefsProvider] Record check-in error: $e');
    }
  }
}

// ============================================
// Providers
// ============================================

/// Nutrition preferences state provider
final nutritionPreferencesProvider =
    StateNotifierProvider<NutritionPreferencesNotifier, NutritionPreferencesState>(
        (ref) {
  // Watch user_id only — full AuthState churns on token refresh. Flush the
  // static in-memory cache on a real account switch.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _nutritionPrefsCacheOwnerUserId) {
    _nutritionPrefsCacheOwnerUserId = userId;
    _nutritionPrefsInMemoryCache = null;
  }
  return NutritionPreferencesNotifier(
    ref.watch(nutritionPreferencesRepositoryProvider),
  );
});

/// Nutrition onboarding completed provider (convenience)
final nutritionOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).onboardingCompleted;
});

/// Current calorie target provider (convenience)
final currentCalorieTargetProvider = Provider<int>((ref) {
  return ref.watch(nutritionPreferencesProvider).currentCalorieTarget;
});

/// Current protein target provider (convenience)
final currentProteinTargetProvider = Provider<int>((ref) {
  return ref.watch(nutritionPreferencesProvider).currentProteinTarget;
});

/// Is training day provider (convenience)
final isTrainingDayProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).isTrainingDay;
});

/// Is fasting day provider (for 5:2, ADF)
final isFastingDayProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).isFastingDay;
});

/// Latest weight provider (convenience)
final latestWeightProvider = Provider<double?>((ref) {
  return ref.watch(nutritionPreferencesProvider).latestWeight;
});

/// Weight trend direction provider
final weightTrendDirectionProvider = Provider<String>((ref) {
  return ref.watch(nutritionPreferencesProvider).weightTrend?.direction ?? 'maintaining';
});

/// Nutrition streak provider
final nutritionStreakProvider = Provider<NutritionStreak?>((ref) {
  return ref.watch(nutritionPreferencesProvider).streak;
});

/// Dynamic targets provider
final dynamicNutritionTargetsProvider = Provider<DynamicNutritionTargets?>((ref) {
  return ref.watch(nutritionPreferencesProvider).dynamicTargets;
});

/// Whether the per-meal-targets feature is enabled (Phase 1c).
final perMealTargetsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(nutritionPreferencesProvider).perMealTargetsEnabled;
});

/// TODAY's per-meal targets (null when disabled). For other dates use
/// [perMealTargetsForDateProvider].
final perMealTargetsTodayProvider =
    Provider<Map<String, MealMacroTargets>?>((ref) {
  return ref.watch(nutritionPreferencesProvider).perMealTargetsToday;
});

/// Per-meal targets for a SPECIFIC date (`yyyy-MM-dd`). The dynamic-targets
/// endpoint returns `per_meal_targets` for the requested day, so a past or
/// future date shows that day's split (training/rest/fasting/cycle adjusted).
///
/// Returns null when the per-meal feature is disabled — gated on the
/// preference flag so we don't fire a network call for users who never
/// enabled it. The TODAY case short-circuits to the already-loaded singleton
/// (no extra round-trip) by reading from the prefs state.
final perMealTargetsForDateProvider = FutureProvider.autoDispose
    .family<Map<String, MealMacroTargets>?, ({String userId, String date})>(
        (ref, args) async {
  // Feature gate — don't fetch when disabled.
  final enabled = ref.watch(perMealTargetsEnabledProvider);
  if (!enabled || args.userId.isEmpty) return null;

  // Today → reuse the singleton already loaded by the prefs notifier (no
  // duplicate fetch, and it reflects optimistic edits).
  final todayKey = () {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }();
  if (args.date == todayKey) {
    return ref.watch(nutritionPreferencesProvider).perMealTargetsToday;
  }

  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  DateTime? parsed;
  try {
    parsed = DateTime.parse(args.date);
  } catch (_) {
    parsed = null;
  }
  try {
    final dyn = await repo.getDynamicTargets(userId: args.userId, date: parsed);
    return dyn.perMealTargets;
  } catch (e) {
    debugPrint(
        '⚠️ [perMealTargetsForDate] fetch failed for ${args.date}: $e');
    return null;
  }
});

// ============================================
// Nutrition UI Preferences Providers
// ============================================

/// Nutrition UI preferences state
class NutritionUIPreferencesState {
  final NutritionUIPreferences? preferences;
  final bool isLoading;
  final String? error;

  const NutritionUIPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
  });

  NutritionUIPreferencesState copyWith({
    NutritionUIPreferences? preferences,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NutritionUIPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get suggested meal type based on preferences and time
  String get suggestedMealType =>
      preferences?.suggestedMealType ?? 'breakfast';

  /// Check if AI tips are disabled
  bool get aiTipsDisabled => preferences?.disableAiTips ?? false;

  /// Check if quick log mode is enabled
  bool get quickLogEnabled => preferences?.quickLogMode ?? true;

  /// Check if compact tracker view is enabled
  bool get compactViewEnabled => preferences?.compactTrackerView ?? false;

  /// Check if macros should be shown on log
  bool get showMacrosOnLog => preferences?.showMacrosOnLog ?? true;
}

/// Nutrition UI preferences notifier
class NutritionUIPreferencesNotifier extends StateNotifier<NutritionUIPreferencesState> {
  final NutritionPreferencesRepository _repository;

  NutritionUIPreferencesNotifier(this._repository)
      : super(const NutritionUIPreferencesState());

  /// Load UI preferences for a user
  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔍 [NutritionUIPrefsProvider] Loading for $userId');
      final prefs = await _repository.getUIPreferences(userId);
      state = state.copyWith(preferences: prefs, isLoading: false);
      debugPrint('✅ [NutritionUIPrefsProvider] Loaded');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle AI tips on/off
  Future<void> toggleAiTips(bool disabled) async {
    if (state.preferences == null) return;
    try {
      debugPrint('🤖 [NutritionUIPrefsProvider] Setting AI tips disabled: $disabled');
      final updated = state.preferences!.copyWith(disableAiTips: disabled);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] AI tips updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set quick log mode
  Future<void> setQuickLogMode(bool enabled) async {
    if (state.preferences == null) return;
    try {
      debugPrint('⚡ [NutritionUIPrefsProvider] Setting quick log mode: $enabled');
      final updated = state.preferences!.copyWith(quickLogMode: enabled);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Quick log mode updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set compact view mode
  Future<void> setCompactView(bool compact) async {
    if (state.preferences == null) return;
    try {
      debugPrint('📐 [NutritionUIPrefsProvider] Setting compact view: $compact');
      final updated = state.preferences!.copyWith(compactTrackerView: compact);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Compact view updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set show macros on log
  Future<void> setShowMacrosOnLog(bool show) async {
    if (state.preferences == null) return;
    try {
      debugPrint('📊 [NutritionUIPrefsProvider] Setting show macros on log: $show');
      final updated = state.preferences!.copyWith(showMacrosOnLog: show);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Show macros updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set default meal type
  Future<void> setDefaultMealType(String mealType) async {
    if (state.preferences == null) return;
    try {
      debugPrint('🍽️ [NutritionUIPrefsProvider] Setting default meal type: $mealType');
      final updated = state.preferences!.copyWith(defaultMealType: mealType);
      final saved = await _repository.updateUIPreferences(updated);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Default meal type updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update all preferences at once
  Future<void> updatePreferences(NutritionUIPreferences prefs) async {
    try {
      debugPrint('💾 [NutritionUIPrefsProvider] Updating all preferences');
      final saved = await _repository.updateUIPreferences(prefs);
      state = state.copyWith(preferences: saved);
      debugPrint('✅ [NutritionUIPrefsProvider] Preferences updated');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reset to defaults
  Future<void> reset(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 [NutritionUIPrefsProvider] Resetting to defaults');
      final prefs = await _repository.resetUIPreferences(userId);
      state = state.copyWith(preferences: prefs, isLoading: false);
      debugPrint('✅ [NutritionUIPrefsProvider] Reset complete');
    } catch (e) {
      debugPrint('❌ [NutritionUIPrefsProvider] Reset error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Nutrition UI preferences provider
final nutritionUIPreferencesProvider =
    StateNotifierProvider<NutritionUIPreferencesNotifier, NutritionUIPreferencesState>(
        (ref) {
  return NutritionUIPreferencesNotifier(
    ref.watch(nutritionPreferencesRepositoryProvider),
  );
});

/// Provider for meal templates
final mealTemplatesProvider = FutureProvider.autoDispose.family<List<MealTemplate>, String?>((ref, mealType) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getTemplates(mealType: mealType);
});

/// Provider for all meal templates (no filter)
final allMealTemplatesProvider = FutureProvider.autoDispose<List<MealTemplate>>((ref) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getTemplates();
});

/// Provider for quick suggestions
final quickSuggestionsProvider = FutureProvider.autoDispose.family<List<QuickSuggestion>, String?>((ref, mealType) async {
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.getQuickSuggestions(mealType: mealType);
});

/// Provider for food search results
final foodSearchProvider = FutureProvider.autoDispose.family<List<FoodSearchResult>, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];
  final repo = ref.watch(nutritionPreferencesRepositoryProvider);
  return repo.searchFoods(query);
});

/// Convenience provider for AI tips disabled state
final aiTipsDisabledProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).aiTipsDisabled;
});

/// Convenience provider for quick log mode
final quickLogModeProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).quickLogEnabled;
});

/// Convenience provider for compact view mode
final compactTrackerViewProvider = Provider<bool>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).compactViewEnabled;
});

/// Convenience provider for suggested meal type
final suggestedMealTypeProvider = Provider<String>((ref) {
  return ref.watch(nutritionUIPreferencesProvider).suggestedMealType;
});
